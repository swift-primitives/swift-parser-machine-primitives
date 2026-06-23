public import Machine_Primitives
@_exported import Parser_Primitives

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
