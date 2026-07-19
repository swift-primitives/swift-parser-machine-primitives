//
//  Machine.Memoization.Table.swift
//  swift-parser-primitives
//
//  Memoization table storing cached parse results.
//

extension Parser.Machine.Memoization {
    /// Memoization table for caching parse results.
    ///
    /// Maps (position, node) keys to cached results.
    package struct Table<Checkpoint: Hashable> {
        @usableFromInline
        var storage: [Key<Checkpoint>: Entry<Checkpoint>]

        package init() {
            self.storage = [:]
        }

        package init(capacity: Int) {
            self.storage = Dictionary(minimumCapacity: capacity)
        }
    }
}

// MARK: - Lookup

extension Parser.Machine.Memoization.Table {
    package func lookup(_ key: Parser.Machine.Memoization.Key<Checkpoint>) -> Parser.Machine.Memoization.Entry<Checkpoint>? {
        storage[key]
    }

    package mutating func store(_ entry: Parser.Machine.Memoization.Entry<Checkpoint>, for key: Parser.Machine.Memoization.Key<Checkpoint>) {
        storage[key] = entry
    }
}

// MARK: - Metrics

extension Parser.Machine.Memoization.Table {
    package var count: Int {
        storage.count
    }

    package var isEmpty: Bool {
        storage.isEmpty
    }

    package mutating func clear() {
        storage.removeAll(keepingCapacity: true)
    }
}

// MARK: - Invalidation

extension Parser.Machine.Memoization.Table where Checkpoint: Comparable {
    /// Invalidates memoization entries affected by an edit.
    ///
    /// Checkpoints are opaque here (`Comparable` only — no arithmetic is
    /// available), so an entry positioned at or after the edit cannot be
    /// soundly rebased to the new input's coordinates: the content that used
    /// to sit at its cached position may have shifted, and this table has no
    /// way to recompute where. Retaining such an entry unmodified (as the
    /// previous `key.position >= edit.oldEnd` clause did) silently returns a
    /// memoized result computed over the wrong content. A success entry is
    /// therefore kept only when its whole span `[key.position, endPosition)`
    /// lies entirely before the edit; a failure entry (no tracked end) is
    /// kept only when it starts before the edit. This sacrifices some cache
    /// reuse across an edit in exchange for never returning a stale result.
    package mutating func invalidate(_ edit: Parser.Machine.Memoization.Edit<Checkpoint>) {
        storage = storage.filter { key, entry in
            switch entry {
            case .success(_, let endPosition):
                return endPosition <= edit.start

            case .failure:
                return key.position < edit.start
            }
        }
    }

    /// Invalidates all memoization entries at or after a position.
    ///
    /// A success entry's parsed span is `[key.position, endPosition)`; it is
    /// dropped whenever that span crosses `position` at all. Checking only
    /// `key.position` (as this previously did) let an entry whose *end*
    /// extended past the cutoff survive, keeping a result that read into the
    /// invalidated region reachable by later lookups.
    package mutating func invalidate(from position: Checkpoint) {
        storage = storage.filter { key, entry in
            switch entry {
            case .success(_, let endPosition):
                return endPosition <= position

            case .failure:
                return key.position < position
            }
        }
    }
}
