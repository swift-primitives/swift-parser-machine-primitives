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
    package struct Key<Checkpoint: Hashable & Sendable>: Hashable, Sendable {
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
