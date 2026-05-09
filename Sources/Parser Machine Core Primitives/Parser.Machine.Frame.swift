public import Machine_Primitives
import Parser_Primitives

extension Parser.Machine {
    /// Frame is a typealias to the core Machine.Frame with Parsing's Frame.Extra for memoization.
    public typealias Frame<Input: Parser_Primitives.Parser.Input.`Protocol` & ~Copyable, Failure: Swift.Error & Sendable> = Machine_Primitives.Machine.Frame<
        Node<Input, Failure>.ID,
        Input.Checkpoint,
        Machine_Primitives.Machine.Capture.Mode.Reference,
        Failure,
        Extra<Input.Checkpoint>
    > where Input: Sendable

    /// Extension point for Parsing-specific frame cases (memoization).
    public enum Extra<Checkpoint> {
        /// Memoization frame - caches result when node completes
        case memoization(node: Ordinal, startPosition: Checkpoint)
    }
}
