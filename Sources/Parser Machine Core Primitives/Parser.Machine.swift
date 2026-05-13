public import Machine_Primitives
@_exported import Parser_Primitives
public import Tagged_Primitives

extension Parser {
    public enum Machine {}
}

// MARK: - Core Type Aliases

extension Parser.Machine {
    /// The capture mode used by Parser.Machine programs.
    ///
    /// Aliases `Machine.Capture.Mode.Unchecked` per [MEM-SEND-013] Pattern B
    /// terminal direction: combinator factories drop their `<T: Sendable>` /
    /// `@Sendable` bounds, the assembled `Parser.Machine.Parser` is non-Sendable
    /// by construction, and consumers transport across isolation domains via
    /// `sending` at the program-transport boundary.
    public typealias Mode = Machine_Primitives.Machine.Capture.Mode.Unchecked

    /// Type-erased value container from Machine Primitives.
    public typealias Value = Machine_Primitives.Machine.Value<Mode>

    /// Transform operations from Machine Primitives.
    public typealias Transform = Machine_Primitives.Machine.Transform

    /// Combine operations from Machine Primitives.
    public typealias Combine = Machine_Primitives.Machine.Combine

    /// Finalize operations from Machine Primitives.
    public typealias Finalize = Machine_Primitives.Machine.Finalize

    /// Next-node selection for flatMap from Machine Primitives.
    public typealias Next = Machine_Primitives.Machine.Next
}

extension Parser.Machine {
    /// A parser built from a defunctionalized program that runs without recursive call-stack growth.
    ///
    /// `Parser` is NOT `Sendable` per [MEM-SEND-013] Pattern B terminal direction.
    /// Consumers transport across isolation domains via `sending` at the
    /// program-transport boundary.
    public struct Parser<Input: Parser_Primitives.Parser.Input.`Protocol` & ~Copyable, Output, Failure: Swift.Error & Sendable>: Parser_Primitives.Parser.`Protocol` {
        package let program: Program<Input, Failure>

        package let root: Node<Input, Failure>.ID

        package init(program: Program<Input, Failure>, root: Node<Input, Failure>.ID) {
            self.program = program
            self.root = root
        }

        public func parse(_ input: inout Input) throws(Failure) -> Output {
            try Parser_Primitives.Parser.Machine.run(program: program, root: root, input: &input, as: Output.self)
        }
    }

    /// A reference to a node in the program, used for recursive grammar definitions.
    public struct Reference<Input: Parser_Primitives.Parser.Input.`Protocol` & ~Copyable, Failure: Swift.Error & Sendable, Output> {
        package let node: Node<Input, Failure>.ID

        package init(node: Node<Input, Failure>.ID) {
            self.node = node
        }
    }

    /// A builder context for constructing machine programs.
    ///
    /// Note: Builder does not conform to Sendable. Program construction should
    /// complete on a single task before the resulting Parser is used.
    public struct Builder<Input: Parser_Primitives.Parser.Input.`Protocol` & ~Copyable, Failure: Swift.Error & Sendable>: ~Copyable {
        package var inner: Machine_Primitives.Machine.Builder<Leaf<Input, Failure>, Failure, Mode>

        package init(maxDepth: Int? = nil) {
            self.inner = Machine_Primitives.Machine.Builder(maxDepth: maxDepth)
        }

        @usableFromInline
        package mutating func allocate(_ node: Node<Input, Failure>) -> Node<Input, Failure>.ID {
            inner.allocate(node)
        }

        /// Access to the capture store for registering closures.
        package var captures: Machine_Primitives.Machine.Capture.Store<Mode> {
            get { inner.captures }
            _modify { yield &inner.captures }
        }

        /// Builds the final immutable program.
        package consuming func build() -> Program<Input, Failure> {
            inner.build()
        }
    }

    /// An expression in the machine program, representing a parser that produces Output.
    public struct Expression<Input: Parser_Primitives.Parser.Input.`Protocol` & ~Copyable, Failure: Swift.Error & Sendable, Output> {
        package let node: Node<Input, Failure>.ID

        @usableFromInline
        package init(node: Node<Input, Failure>.ID) {
            self.node = node
        }
    }
}
