//
//  Machine.Memoization.Entry.swift
//  swift-parser-primitives
//
//  Cached parse result: success or failure.
//

extension Parser.Machine.Memoization {
    /// Cached parse result.
    ///
    /// For packrat parsing, both successes and failures are cached.
    /// Caching failures is essential for linear-time guarantees.
    package enum Entry<Checkpoint> {
        /// Successful parse with output and end position.
        case success(output: Parser.Machine.Value, end: Checkpoint)

        /// Failed parse at this position.
        ///
        /// Carries the original typed failure so a later cache hit on this
        /// entry can re-throw the identical error instead of losing type
        /// information. The boxed value is always the `Failure` type of the
        /// `Parser.Machine.run<Input, Output, Failure>` invocation that
        /// populated this entry — see `handleMemoizedFailure`'s
        /// `.extra(.memoization)` arm in `Parser.Machine.Run.Memoization.swift`,
        /// the sole writer of this case.
        case failure(any Swift.Error)
    }
}

// MARK: - Predicates

extension Parser.Machine.Memoization.Entry {
    package var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }

    package var isFailure: Bool {
        switch self {
        case .success: return false
        case .failure: return true
        }
    }
}
