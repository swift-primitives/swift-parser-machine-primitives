//
//  Machine.Run.Memoization.swift
//  swift-parser-primitives
//
//  Memoized program execution.
//

package import Input_Primitives
package import Machine_Primitives
package import Parser_Primitives
internal import Stack_Primitives
package import Tagged_Primitives

extension Parser.Machine {
    /// Executes the program with memoization.
    ///
    /// Caches parse results at each (position, node) pair,
    /// enabling linear-time parsing and incremental re-parsing.
    package static func run<Input, Output, Failure>(
        program: Program<Input, Failure>,
        root: Node<Input, Failure>.ID,
        input: inout Input,
        memoization: inout Memoization.Table<Input.Checkpoint>,
        as outputType: Output.Type
    ) throws(Failure) -> Output
    where
        Input: Input_Primitives.Input.`Protocol` & ~Copyable,
        Input.Checkpoint: Hashable,
        Failure: Swift.Error
    {
        typealias Value = Parser_Primitives.Parser.Machine.Value
        typealias Frame = Parser_Primitives.Parser.Machine.Frame<Input, Failure>
        typealias Node = Parser_Primitives.Parser.Machine.Node<Input, Failure>
        typealias Recovery = Parser_Primitives.Parser.Machine.Failure.Recovery
        typealias MemoKey = Parser_Primitives.Parser.Machine.Memoization.Key<Input.Checkpoint>
        typealias MemoEntry = Parser_Primitives.Parser.Machine.Memoization.Entry<Input.Checkpoint>

        var current = root
        // Pre-allocate stack capacity based on maxDepth or reasonable default.
        // The 4x multiplier accounts for worst-case frame usage per recursion level:
        // - 1 recursiveExit frame per level
        // - Up to 3 additional frames for combinator chains (sequence, map, oneOf, etc.)
        let depthEstimate = (program.maxDepth ?? 10000) * 4
        // Provably-safe conversion: depthEstimate is a non-negative Int
        // ((maxDepth ?? 10000) * 4), so Count construction cannot fail.
        // swift-format-ignore: NeverUseForceTry
        var frames = Stack<Frame>(minimumCapacity: try! Index<Frame>.Count(depthEstimate))
        var arena = Value.Arena(capacity: depthEstimate * 2)

        var depth = 0
        var pendingHandle: Value.Handle? = nil

        func handleMemoizedFailure<E: Swift.Error>(
            error: E,
            frames: inout Stack<Frame>,
            arena: inout Value.Arena,
            input: inout Input,
            depth: inout Int,
            memoization: inout Memoization.Table<Input.Checkpoint>
        ) throws(Failure) -> Recovery {
            while let frame = frames.pop() {
                switch frame {
                case .oneOf(let alternatives, let index, let savedCheckpoint):
                    if index < alternatives.count {
                        input.seek(to: savedCheckpoint)
                        frames.push(
                            .oneOf(
                                alternatives: alternatives,
                                index: index + 1,
                                savedCheckpoint: savedCheckpoint
                            )
                        )
                        return .continueWith(alternatives[index].retag(Recovery.Tag.self))
                    }

                case .many(_, let savedCheckpoint, let resultHandles, let finalize):
                    input.seek(to: savedCheckpoint)
                    var results: [Value] = []
                    results.reserveCapacity(resultHandles.count)
                    for handle in resultHandles {
                        results.append(arena.release(handle))
                    }
                    let finalValue = finalize.finalize(using: program.captures, results)
                    let handle = arena.allocate(finalValue)
                    return .handleReady(handle)

                case .optional(let savedCheckpoint, _, let noneHandle):
                    input.seek(to: savedCheckpoint)
                    return .handleReady(noneHandle)

                case .fold(_, let savedCheckpoint, let accHandle, _):
                    input.seek(to: savedCheckpoint)
                    return .handleReady(accHandle)

                case .recursiveExit:
                    depth -= 1

                case .extra(.memoization(let node, let startPosition)):
                    // Only a value that is actually this run's `Failure` may be
                    // memoized here: `error` is `E: Swift.Error` generically, and
                    // the `.ref` depth-exceeded call site (below) passes a
                    // `Parser.Machine.Runtime.Error` — a *different* type from the
                    // grammar's own `Failure` — when the machine hits
                    // `program.maxDepth`. Storing that verbatim used to let a
                    // `Runtime.Error` masquerade as this table's `Failure`-typed
                    // `.failure` payload, so a later cache hit reaching the
                    // `.propagate` arm below would downcast it to `Failure` and
                    // crash (`storedError as? Failure` failing is exactly the
                    // "cached failure type mismatch" `fatalError`).
                    //
                    // Skipping the store for a non-`Failure` error is also the
                    // *sound* choice, not just the crash-avoiding one: depth is a
                    // function of the call path that reached this (position, node)
                    // pair, not of position alone, so a depth-exceeded outcome is
                    // not a stable fact to cache at this key in the first place —
                    // a different call path could reach the same (position, node)
                    // pair at a different depth and get a different answer. Not
                    // caching it means the depth check is simply re-evaluated
                    // (against the *current* depth) the next time this node is
                    // reached, which is the only sound behavior.
                    //
                    // This makes every `.failure` entry in the table provably
                    // `Failure`-typed by construction — this is the only writer of
                    // `.failure` (see `Entry.failure`'s doc comment) — so the
                    // `storedError as? Failure` downcast at the cache-hit
                    // `.propagate` arm, below, can no longer fail.
                    if let failure = error as? Failure {
                        let key = MemoKey(position: startPosition, node: node)
                        memoization.store(.failure(failure), for: key)
                    }

                case .map, .tryMap, .flatMap, .sequence:
                    continue
                }
            }
            return .propagate
        }

        while true {
            if let handle = pendingHandle {
                pendingHandle = nil
                let value = arena.release(handle)

                if frames.isEmpty {
                    return value[as: Output.self]
                }

                guard let frame = frames.pop() else {
                    fatalError("Internal error: expected frame on stack")
                }

                switch frame {
                case .map(let transform):
                    let transformed = transform.apply(using: program.captures, value)
                    pendingHandle = arena.allocate(transformed)

                case .tryMap(let transform):
                    do throws(Failure) {
                        let transformed = try transform.apply(using: program.captures, value)
                        pendingHandle = arena.allocate(transformed)
                    } catch {
                        switch try handleMemoizedFailure(
                            error: error,
                            frames: &frames,
                            arena: &arena,
                            input: &input,
                            depth: &depth,
                            memoization: &memoization
                        ) {
                        case .continueWith(let recovered):
                            current = recovered.retag(Node.self)

                        case .handleReady(let recoveredHandle):
                            pendingHandle = recoveredHandle

                        case .propagate:
                            // `error` is the machine's unified `Failure` (thrown by
                            // `transform.apply(…) throws(Failure)`); bind it to a
                            // `Failure`-typed local to re-throw without weakening the
                            // enclosing `throws(Failure)` contract. A bare `throw error`
                            // trips a spurious `any Error` catch-inference here.
                            let failure: Failure = error
                            throw failure
                        }
                    }

                case .flatMap(let next):
                    let erasedID = next.next(using: program.captures, value)
                    current = erasedID.retag(Node.self)

                case .sequence(.second(let b, let combine)):
                    let firstHandle = arena.allocate(value)
                    frames.push(.sequence(.combine(firstHandle: firstHandle, combine: combine)))
                    current = b

                case .sequence(.combine(let firstHandle, let combine)):
                    let first = arena.release(firstHandle)
                    let combined = combine.combine(using: program.captures, first, value)
                    pendingHandle = arena.allocate(combined)

                case .oneOf:
                    pendingHandle = arena.allocate(value)

                case .many(let child, let priorCheckpoint, var resultHandles, let finalize):
                    let handle = arena.allocate(value)
                    resultHandles.append(handle)
                    let checkpoint = input.checkpoint
                    if checkpoint == priorCheckpoint {
                        // PEG progress guard: the child succeeded without
                        // consuming input. Looping back into it would repeat
                        // the identical zero-width success forever, growing
                        // `resultHandles`/the arena without bound. Standard
                        // packrat semantics: stop the repetition as soon as
                        // the child stops making progress, keeping the
                        // result it already produced.
                        var results: [Value] = []
                        results.reserveCapacity(resultHandles.count)
                        for resultHandle in resultHandles {
                            results.append(arena.release(resultHandle))
                        }
                        let finalValue = finalize.finalize(using: program.captures, results)
                        pendingHandle = arena.allocate(finalValue)
                    } else {
                        frames.push(.many(child: child, savedCheckpoint: checkpoint, resultHandles: resultHandles, finalize: finalize))
                        current = child
                    }

                case .fold(let child, let priorCheckpoint, let accHandle, let combine):
                    let acc = arena.release(accHandle)
                    let newAcc = combine.combine(using: program.captures, acc, value)
                    let checkpoint = input.checkpoint
                    if checkpoint == priorCheckpoint {
                        // Same progress guard as `.many`, above.
                        pendingHandle = arena.allocate(newAcc)
                    } else {
                        frames.push(.fold(child: child, savedCheckpoint: checkpoint, accumulatorHandle: arena.allocate(newAcc), combine: combine))
                        current = child
                    }

                case .optional(_, let wrapSome, let noneHandle):
                    _ = arena.release(noneHandle)
                    let wrapped = wrapSome.apply(using: program.captures, value)
                    pendingHandle = arena.allocate(wrapped)

                case .recursiveExit:
                    depth -= 1
                    pendingHandle = arena.allocate(value)

                case .extra(.memoization(let node, let startPosition)):
                    // Cache the successful result
                    let key = MemoKey(position: startPosition, node: node)
                    let entry = MemoEntry.success(output: value, end: input.checkpoint)
                    memoization.store(entry, for: key)
                    pendingHandle = arena.allocate(value)
                }

                continue
            }

            // Check memoization before executing node
            let memoKey = MemoKey(position: input.checkpoint, node: current.underlying)
            if let cached = memoization.lookup(memoKey) {
                switch cached {
                case .success(let output, let endPosition):
                    // Cache hit: use cached result
                    input.seek(to: endPosition)
                    pendingHandle = arena.allocate(output)
                    continue

                case .failure(let storedError):
                    // Cached failure: propagate through failure handling
                    switch try handleMemoizedFailure(
                        error: storedError,
                        frames: &frames,
                        arena: &arena,
                        input: &input,
                        depth: &depth,
                        memoization: &memoization
                    ) {
                    case .continueWith(let recovered):
                        current = recovered.retag(Node.self)
                        continue

                    case .handleReady(let handle):
                        pendingHandle = handle
                        continue

                    case .propagate:
                        // A repeat parse of previously-failed input hits this
                        // cached entry and must re-throw the *same* typed
                        // failure that originally propagated to the root
                        // without a recovery frame — not crash the process.
                        //
                        // `storedError as? Failure` is provably non-failing here,
                        // not merely "unreachable in practice": `.extra(.memoization)`
                        // (above) is the *only* writer of `.failure`, and it now
                        // only stores when `error as? Failure` itself already
                        // succeeded — so every `.failure` entry in this table is,
                        // by construction, a boxed `Failure`. (An earlier version
                        // of this guard rested that claim on a different premise —
                        // "this `Table`'s sole owner never mixes `Failure` types" —
                        // which was false: the `.ref` depth-exceeded path below
                        // used to pass a `Parser.Machine.Runtime.Error`, a
                        // *different* type from this run's `Failure`, into this
                        // same storage arm, and it got boxed verbatim. That is
                        // what the `guard`/`fatalError` below defends against; it
                        // is kept as a documented invariant check, not a reachable
                        // error path.)
                        guard let typedFailure = storedError as? Failure else {
                            preconditionFailure(
                                "Internal error: cached failure type mismatch — every `.failure` entry must be `Failure`-typed by construction (see `.extra(.memoization)`, above)"
                            )
                        }
                        throw typedFailure
                    }
                }
            }

            // Cache miss: push memoization frame and execute
            frames.push(.extra(.memoization(node: current.underlying, startPosition: input.checkpoint)))

            let node = program[current]

            switch node {
            case .leaf(let leaf):
                do throws(Failure) {
                    let value = try leaf.run(&input)
                    pendingHandle = arena.allocate(value)
                } catch {
                    switch try handleMemoizedFailure(
                        error: error,
                        frames: &frames,
                        arena: &arena,
                        input: &input,
                        depth: &depth,
                        memoization: &memoization
                    ) {
                    case .continueWith(let recovered):
                        current = recovered.retag(Node.self)

                    case .handleReady(let handle):
                        pendingHandle = handle

                    case .propagate:
                        throw error
                    }
                }

            case .pure(let value):
                pendingHandle = arena.allocate(value)

            case .map(let child, let transform):
                frames.push(.map(transform: transform))
                current = child

            case .tryMap(let child, let transform):
                frames.push(.tryMap(transform: transform))
                current = child

            case .flatMap(let child, let next):
                frames.push(.flatMap(next: next))
                current = child

            case .sequence(let a, let b, let combine):
                frames.push(.sequence(.second(b: b, combine: combine)))
                current = a

            case .oneOf(let alternatives):
                guard !alternatives.isEmpty else {
                    fatalError("Empty oneOf")
                }
                let checkpoint = input.checkpoint
                if alternatives.count > 1 {
                    frames.push(
                        .oneOf(
                            alternatives: alternatives,
                            index: 1,
                            savedCheckpoint: checkpoint
                        )
                    )
                }
                current = alternatives[0]

            case .many(let child, let finalize):
                let checkpoint = input.checkpoint
                frames.push(.many(child: child, savedCheckpoint: checkpoint, resultHandles: [], finalize: finalize))
                current = child

            case .fold(let child, let initial, let combine):
                let checkpoint = input.checkpoint
                frames.push(.fold(child: child, savedCheckpoint: checkpoint, accumulatorHandle: arena.allocate(initial), combine: combine))
                current = child

            case .optional(let child, let wrapSome, let noneValue):
                let checkpoint = input.checkpoint
                let noneHandle = arena.allocate(noneValue)
                frames.push(.optional(savedCheckpoint: checkpoint, wrapSome: wrapSome, noneHandle: noneHandle))
                current = child

            case .ref(let target):
                if let limit = program.maxDepth, depth >= limit {
                    let error = Parser_Primitives.Parser.Machine.Runtime.Error.depthExceeded(limit: limit)
                    switch try handleMemoizedFailure(
                        error: error,
                        frames: &frames,
                        arena: &arena,
                        input: &input,
                        depth: &depth,
                        memoization: &memoization
                    ) {
                    case .continueWith(let recovered):
                        current = recovered.retag(Node.self)

                    case .handleReady(let handle):
                        pendingHandle = handle

                    case .propagate:
                        fatalError("Depth exceeded with no handler")
                    }
                } else {
                    depth += 1
                    frames.push(.recursiveExit)
                    current = target
                }

            case .hole:
                fatalError("Unpatched hole in program")
            }
        }
    }
}
