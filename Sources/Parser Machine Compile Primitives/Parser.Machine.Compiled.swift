//
//  Machine.Compiled.swift
//  swift-parser-primitives
//
//  Lazy-compiling parser wrapper with cached program.
//

public import Input_Primitives
public import Machine_Primitives

extension Parser.Machine {
    /// A parser wrapper that lazily compiles to a Machine program.
    ///
    /// `Compiled` delays compilation until the first parse, then caches
    /// the compiled program for subsequent parses. This provides:
    /// - Zero overhead for parsers that are never used
    /// - Amortized compilation cost over multiple parses
    /// - Stack-safe execution for deeply nested structures
    ///
    /// ## Usage
    ///
    /// ```swift
    /// var compiled = myParser.compiled(using: .leaf)
    /// let result = try compiled.parse(&input)  // Compiles on first call
    /// let result2 = try compiled.parse(&input2) // Uses cached program
    /// ```
    ///
    /// ## Thread Safety
    ///
    /// `Compiled` is NOT `Sendable`. Use it within a single isolation domain.
    /// For cross-task sharing, use `prepared()` which returns an immutable
    /// `Prepared` wrapper that is conditionally `Sendable`.
    ///
    /// ```swift
    /// let prepared = myParser.compiled(using: .leaf).prepared()
    /// // `prepared` can be shared across tasks
    /// ```
    public struct Compiled<P: Parser_Primitives.Parser.`Protocol` & ~Copyable>: ~Copyable
    where
        P.Input: Input_Primitives.Input.`Protocol`,
        P.Failure: Swift.Error
    {
        @usableFromInline
        let cache: Cache

        /// Creates a compiled parser wrapper.
        ///
        /// The parser is consumed into the wrapper and held by an internal
        /// cache that compiles on first use. The parser may be `~Copyable`
        /// because the cache moves the parser into the Machine program once
        /// and then drops the slot.
        ///
        /// - Parameters:
        ///   - source: The parser to compile. Consumed.
        ///   - witness: The compilation witness.
        @inlinable
        public init(source: consuming P, witness: Compile.Witness<P>) {
            self.cache = Cache(source: source, witness: witness)
        }

        /// Compiles eagerly and returns an immutable, shareable parser.
        ///
        /// The returned `Prepared` wrapper is conditionally `Sendable` and
        /// safe for cross-task sharing. Use this when you need to share
        /// a compiled parser across actors or concurrent operations.
        ///
        /// - Returns: An immutable prepared parser.
        @inlinable
        public borrowing func prepared() -> Prepared<P> {
            let result = cache.getOrCompile()
            return Prepared(program: result.program, root: result.root)
        }
    }
}

// MARK: - Conditional Copyable Conformance

// `Compiled` is `~Copyable` when `P` is `~Copyable` and `Copyable` when `P`
// is `Copyable`. For `Copyable` P, this preserves the original reference-
// sharing semantics: copies of `Compiled` share the same `Cache` instance
// via class reference, amortizing compilation cost across copies. For
// `~Copyable` P, no copies exist (the wrapper is uniquely owned).
extension Parser.Machine.Compiled: Copyable where P: Copyable {}

// MARK: - Result

extension Parser.Machine.Compiled where P: ~Copyable {
    /// The cached compilation result.
    @usableFromInline
    struct Result {
        @usableFromInline
        let program: Parser.Machine.Program<P.Input, P.Failure>

        @usableFromInline
        let root: Parser.Machine.Node<P.Input, P.Failure>.ID

        @usableFromInline
        init(
            program: Parser.Machine.Program<P.Input, P.Failure>,
            root: Parser.Machine.Node<P.Input, P.Failure>.ID
        ) {
            self.program = program
            self.root = root
        }
    }
}

// MARK: - Cache

extension Parser.Machine.Compiled where P: ~Copyable {
    /// Reference-type cache for lazy compilation.
    ///
    /// Owns the source parser as an `Optional<P>` so it can consume the
    /// parser on first compile (moving it into the Machine program) and
    /// then drop the slot. This is the structural mechanism that allows
    /// `P: ~Copyable`: the parser is moved exactly once into the program,
    /// not borrowed N times.
    ///
    /// Not Sendable - use within single isolation domain.
    @usableFromInline
    final class Cache {
        @usableFromInline
        var compiled: Result?

        /// Source parser pending compilation; consumed to `nil` on first
        /// call to `getOrCompile()` once `compiled` is populated.
        @usableFromInline
        var source: P?

        @usableFromInline
        let witness: Parser.Machine.Compile.Witness<P>

        @usableFromInline
        init(source: consuming P, witness: Parser.Machine.Compile.Witness<P>) {
            self.compiled = nil
            self.source = consume source
            self.witness = witness
        }

        @usableFromInline
        func getOrCompile() -> Result {
            if let existing = compiled {
                return existing
            }
            guard let parser = source.take() else {
                // Unreachable: source is non-nil until consumed here, and
                // this branch only runs once because `compiled` is populated
                // before the next call.
                fatalError("Parser.Machine.Compiled.Cache: source consumed but result missing")
            }
            var builder = Parser.Machine.Builder<P.Input, P.Failure>()
            let expression = witness.compile(parser, into: &builder)
            let result = Result(
                program: builder.build(),
                root: expression.node
            )
            compiled = result
            return result
        }
    }
}

// MARK: - Parser Conformance

extension Parser.Machine.Compiled: Parser_Primitives.Parser.`Protocol` where P: ~Copyable {
    public typealias Input = P.Input
    public typealias Output = P.Output
    public typealias Failure = P.Failure

    public borrowing func parse(_ input: inout Input) throws(Failure) -> Output {
        let result = cache.getOrCompile()
        return try Parser.Machine.run(program: result.program, root: result.root, input: &input, as: Output.self)
    }
}
