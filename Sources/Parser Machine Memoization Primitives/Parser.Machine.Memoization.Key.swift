//
//  Machine.Memoization.Key.swift
//  swift-parser-primitives
//
//  Cache key: (position, node) pair.
//

extension Parser.Machine.Memoization {
    /// Cache key for memoization: (position, node) pair.
    ///
    /// Each unique combination of input position and parser node
    /// produces at most one cached result.
    package struct Key<Checkpoint: Hashable>: Hashable {
        /// The input position where parsing started.
        package let position: Checkpoint

        /// The node index in the program.
        package let node: Ordinal

        package init(position: Checkpoint, node: Ordinal) {
            self.position = position
            self.node = node
        }
    }
}

// MARK: - Conditional Sendable
//
// Data-container conditional Sendable per [MEM-SEND-013] out-of-scope carve-out.
extension Parser.Machine.Memoization.Key: Sendable where Checkpoint: Sendable {}
