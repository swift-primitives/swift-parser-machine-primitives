import Parser_Primitives
public import Machine_Primitives
internal import Tagged_Primitives

extension Parser.Machine {
    /// Node is a typealias to the core Machine.Node with Parsing's Leaf type.
    public typealias Node<Input: Parser_Primitives.Parser.Input.`Protocol` & ~Copyable, Failure: Error & Sendable> =
        Machine_Primitives.Machine.Node<Leaf<Input, Failure>, Failure, Machine_Primitives.Machine.Capture.Mode.Reference>
        where Input: Sendable

    /// Parsing-specific leaf: a closure-based parser operation.
    @safe
    // WHY: Category D — structural Sendable workaround (SP-4).
    // WHY: Stores @Sendable closure but phantom Input: ~Copyable blocks inference.
    // WHEN TO REMOVE: When compiler gains structural Sendable through phantom params.
    // TRACKING: unsafe-audit-findings.md Category D SP-4.
    public struct Leaf<Input: Parser_Primitives.Parser.Input.`Protocol` & ~Copyable, Failure: Error & Sendable>: @unchecked Sendable
    where Input: Sendable {
        @usableFromInline
        package let run: @Sendable (inout Input) throws(Failure) -> Value

        @usableFromInline
        package init(_ run: @Sendable @escaping (inout Input) throws(Failure) -> Value) {
            self.run = run
        }
    }
}
