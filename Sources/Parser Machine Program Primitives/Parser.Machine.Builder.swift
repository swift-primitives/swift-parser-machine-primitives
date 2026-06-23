public import Machine_Primitives
import Parser_Primitives

extension Parser.Machine {
    /// A builder context for constructing machine programs.
    ///
    /// Note: Builder does not conform to Sendable. Program construction should
    /// complete on a single task before the resulting Parser is used.
    public struct Builder<Input: Input_Primitives.Input.`Protocol` & ~Copyable, Failure: Swift.Error>: ~Copyable {
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
}
