//
//  Machine.Parser+Compiled.swift
//  swift-parser-primitives
//
//  Parse accessor extensions for Machine compilation.
//

// MARK: - Compilation Variants (Copyable P)

extension Parser.Parse
where
    P.Input: Input_Primitives.Input.`Protocol`,
    P.Failure: Swift.Error
{
    /// Creates a lazily-compiled version of this parser.
    ///
    /// The returned parser compiles on first use and caches the program
    /// for subsequent parses. It is NOT `Sendable`.
    ///
    /// For cross-task sharing, use `prepared(using:)` instead.
    ///
    /// - Parameter witness: The compilation witness.
    /// - Returns: A lazy-compiling parser wrapper.
    public func compiled(
        using witness: Parser.Machine.Compile.Witness<P>
    ) -> Parser.Machine.Compiled<P> {
        Parser.Machine.Compiled(source: parser, witness: witness)
    }

    /// Creates an eagerly-compiled, immutable parser.
    ///
    /// The returned parser is fully compiled. It is NOT `Sendable` per
    /// [MEM-SEND-013] Pattern B terminal direction; consumers transport
    /// across isolation domains via `sending` at the program-transport
    /// boundary.
    ///
    /// - Parameter witness: The compilation witness.
    /// - Returns: An immutable prepared parser.
    public func prepared(
        using witness: Parser.Machine.Compile.Witness<P>
    ) -> Parser.Machine.Prepared<P> {
        Parser.Machine.Prepared(source: parser, witness: witness)
    }

    /// Creates a lazily-compiled version using leaf compilation.
    ///
    /// Convenience that uses `.leaf` as the witness. The returned parser
    /// is NOT `Sendable`.
    ///
    /// - Returns: A lazy-compiling parser wrapper.
    public func compiled() -> Parser.Machine.Compiled<P> {
        compiled(using: .leaf)
    }

    /// Creates an eagerly-compiled, immutable parser using leaf compilation.
    ///
    /// Convenience that uses `.leaf` as the witness. The returned parser
    /// is NOT `Sendable`; consumers transport via `sending` at boundaries.
    ///
    /// - Returns: An immutable prepared parser.
    public func prepared() -> Parser.Machine.Prepared<P> {
        prepared(using: .leaf)
    }
}

// MARK: - Compilation Variants (~Copyable P)

extension Parser.Parse
where
    P: ~Copyable,
    P.Input: Input_Primitives.Input.`Protocol`,
    P.Failure: Swift.Error
{
    /// Creates a lazily-compiled version of a `~Copyable` parser.
    ///
    /// Consuming variant — `self` is consumed into the Machine.Compiled
    /// wrapper. The returned parser compiles on first use and caches the
    /// program for subsequent parses. NOT `Sendable`.
    ///
    /// - Parameter witness: The compilation witness.
    /// - Returns: A lazy-compiling parser wrapper.
    public consuming func compiled(
        using witness: Parser.Machine.Compile.Witness<P>
    ) -> Parser.Machine.Compiled<P> {
        Parser.Machine.Compiled(source: parser, witness: witness)
    }

    /// Creates an eagerly-compiled, immutable parser from a `~Copyable`
    /// parser.
    ///
    /// Consuming variant. The returned parser is fully compiled. NOT
    /// `Sendable` per [MEM-SEND-013] Pattern B terminal direction;
    /// consumers transport across isolation domains via `sending` at the
    /// program-transport boundary.
    ///
    /// - Parameter witness: The compilation witness.
    /// - Returns: An immutable prepared parser.
    public consuming func prepared(
        using witness: Parser.Machine.Compile.Witness<P>
    ) -> Parser.Machine.Prepared<P> {
        Parser.Machine.Prepared(source: parser, witness: witness)
    }

    /// Creates a lazily-compiled version of a `~Copyable` parser using
    /// leaf compilation.
    ///
    /// Consuming convenience using `.leaf` as the witness. NOT `Sendable`.
    ///
    /// - Returns: A lazy-compiling parser wrapper.
    public consuming func compiled() -> Parser.Machine.Compiled<P> {
        compiled(using: .leaf)
    }

    /// Creates an eagerly-compiled, immutable parser from a `~Copyable`
    /// parser using leaf compilation.
    ///
    /// Consuming convenience using `.leaf` as the witness. NOT `Sendable`;
    /// consumers transport via `sending` at boundaries.
    ///
    /// - Returns: An immutable prepared parser.
    public consuming func prepared() -> Parser.Machine.Prepared<P> {
        prepared(using: .leaf)
    }
}
