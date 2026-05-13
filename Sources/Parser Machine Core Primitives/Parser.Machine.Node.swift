public import Machine_Primitives
import Parser_Primitives
internal import Tagged_Primitives

extension Parser.Machine {
    /// Node is a typealias to the core Machine.Node with Parsing's Leaf type.
    public typealias Node<Input: Parser_Primitives.Parser.Input.`Protocol` & ~Copyable, Failure: Swift.Error & Sendable> =
        Machine_Primitives.Machine.Node<Leaf<Input, Failure>, Failure, Mode>

    /// Parsing-specific leaf: a closure-based parser operation.
    ///
    /// `Leaf` is NOT `Sendable` per [MEM-SEND-013] Pattern B terminal direction.
    /// Parser closures stored in `run` may capture non-Sendable state; consumers
    /// transport assembled programs across isolation domains via `sending` at
    /// the program-transport boundary, not via structural Sendable conformance
    /// on the leaf.
    public struct Leaf<Input: Parser_Primitives.Parser.Input.`Protocol` & ~Copyable, Failure: Swift.Error & Sendable> {
        @usableFromInline
        package let run: (inout Input) throws(Failure) -> Value

        @usableFromInline
        package init(_ run: @escaping (inout Input) throws(Failure) -> Value) {
            self.run = run
        }
    }
}
