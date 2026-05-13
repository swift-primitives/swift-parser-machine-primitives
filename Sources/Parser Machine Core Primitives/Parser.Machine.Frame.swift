public import Machine_Primitives
import Parser_Primitives

extension Parser.Machine {
    /// Frame is a typealias to the core Machine.Frame with Parsing's Frame.Extra for memoization.
    public typealias Frame<Input: Parser_Primitives.Parser.Input.`Protocol` & ~Copyable, Failure: Swift.Error & Sendable> = Machine_Primitives.Machine.Frame<
        Node<Input, Failure>.ID,
        Input.Checkpoint,
        Mode,
        Failure,
        Extra<Input.Checkpoint>
    >

    /// Extension point for Parsing-specific frame cases (memoization).
    public enum Extra<Checkpoint> {
        /// Memoization frame - caches result when node completes
        case memoization(node: Ordinal, startPosition: Checkpoint)
    }
}
