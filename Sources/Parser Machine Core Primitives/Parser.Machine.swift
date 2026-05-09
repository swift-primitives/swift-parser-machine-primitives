public import Machine_Primitives
@_exported import Parser_Primitives
public import Tagged_Primitives

extension Parser {
    public enum Machine {}
}

// MARK: - Core Type Aliases

extension Parser.Machine {
    /// Type-erased value container from Machine Primitives.
    public typealias Value = Machine_Primitives.Machine.Value<Machine_Primitives.Machine.Capture.Mode.Reference>

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
    /// Note: Parser does not conform to Sendable because the underlying Program contains
    /// closures. For cross-task sharing, use explicit Sendable wrappers with documented invariants.
    public struct Parser<Input: Parser_Primitives.Parser.Input.`Protocol` & ~Copyable, Output, Failure: Swift.Error & Sendable>: Parser_Primitives.Parser.`Protocol`
    where Input: Sendable, Output: Sendable {
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
    public struct Reference<Input: Parser_Primitives.Parser.Input.`Protocol` & ~Copyable, Failure: Swift.Error & Sendable, Output>: Sendable
    where Input: Sendable {
        package let node: Node<Input, Failure>.ID

        package init(node: Node<Input, Failure>.ID) {
            self.node = node
        }
    }

    /// The capture mode used by Parser.Machine programs.
    public typealias Mode = Machine_Primitives.Machine.Capture.Mode.Reference

    /// A builder context for constructing machine programs.
    ///
    /// Note: Builder does not conform to Sendable. Program construction should
    /// complete on a single task before the resulting Parser is used.
    public struct Builder<Input: Parser_Primitives.Parser.Input.`Protocol` & ~Copyable, Failure: Swift.Error & Sendable>: ~Copyable
    where Input: Sendable {
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
    public struct Expression<Input: Parser_Primitives.Parser.Input.`Protocol` & ~Copyable, Failure: Swift.Error & Sendable, Output>: Sendable
    where Input: Sendable {
        package let node: Node<Input, Failure>.ID

        @usableFromInline
        package init(node: Node<Input, Failure>.ID) {
            self.node = node
        }
    }
}
