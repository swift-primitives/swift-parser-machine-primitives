import Testing
import Parser_Machine_Parse_Primitives
import Parser_Machine_Combinator_Primitives
import Parser_Primitives_Test_Support

// MARK: - Helpers for Recursive Grammar

private struct OpenParen: Parser.`Protocol`, Sendable {
    enum Error: Swift.Error, Sendable { case expected }
    func parse(_ input: inout Input) throws(Error) -> Void {
        guard input.first == UInt8(ascii: "(") else { throw .expected }
        try! input.advance()
    }
}

private struct CloseParen: Parser.`Protocol`, Sendable {
    enum Error: Swift.Error, Sendable { case expected }
    func parse(_ input: inout Input) throws(Error) -> Void {
        guard input.first == UInt8(ascii: ")") else { throw .expected }
        try! input.advance()
    }
}

private enum TestError: Error, Sendable {
    case openParen
    case closeParen
}

// MARK: - Suite

@Suite("Parser.Machine.Parser.Parse.Incremental")
struct ParserMachineIncrementalTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: - Unit

extension ParserMachineIncrementalTests.Unit {
    @Test
    func `incremental context parses correctly`() throws {
        let parser: Parser.Machine.Parser<Input, UInt8, MatchByte.Error> = Parser.Machine.build { builder in
            Parser.Machine.leaf(MatchByte(expected: 65), in: &builder)
        }

        var ctx = parser.parse.incremental
        var input = Input([65, 66, 67])
        let result = try ctx(&input)
        #expect(result == 65)
    }

    @Test
    func `memoization table populates during parsing`() throws {
        let parser: Parser.Machine.Parser<Input, UInt8, MatchByte.Error> = Parser.Machine.build { builder in
            Parser.Machine.leaf(MatchByte(expected: 65), in: &builder)
        }

        var ctx = parser.parse.incremental
        #expect(ctx.isEmpty)

        var input = Input([65])
        _ = try ctx(&input)
        #expect(ctx.count > 0)
    }

    @Test
    func `clear removes all cached entries`() throws {
        let parser: Parser.Machine.Parser<Input, UInt8, MatchByte.Error> = Parser.Machine.build { builder in
            Parser.Machine.leaf(MatchByte(expected: 65), in: &builder)
        }

        var ctx = parser.parse.incremental
        var input = Input([65])
        _ = try ctx(&input)
        #expect(ctx.count > 0)

        ctx.clear()
        #expect(ctx.isEmpty)
    }

    @Test
    func `re-parsing produces same result`() throws {
        let parser: Parser.Machine.Parser<Input, UInt8, MatchByte.Error> = Parser.Machine.build { builder in
            Parser.Machine.leaf(MatchByte(expected: 65), in: &builder)
        }

        var ctx = parser.parse.incremental

        var input1 = Input([65])
        let result1 = try ctx(&input1)

        var input2 = Input([65])
        let result2 = try ctx(&input2)

        #expect(result1 == result2)
    }
}

// MARK: - Edge Cases

extension ParserMachineIncrementalTests.EdgeCase {
    @Test
    func `invalidate from position clears entries at or after`() throws {
        let parser: Parser.Machine.Parser<Input, (UInt8, UInt8), MatchByte.Error> = Parser.Machine.build { builder in
            let first = Parser.Machine.leaf(MatchByte(expected: 65), in: &builder)
            let second = Parser.Machine.leaf(MatchByte(expected: 66), in: &builder)
            return Parser.Machine.sequence(first, second, combine: { ($0, $1) }, in: &builder)
        }

        var ctx = parser.parse.incremental
        var input = Input([65, 66])
        _ = try ctx(&input)

        let countBefore = ctx.count
        #expect(countBefore > 0)

        ctx.invalidate(from: 1)
        #expect(ctx.count < countBefore)
    }

    @Test
    func `invalidate with edit descriptor removes affected entries`() throws {
        let parser: Parser.Machine.Parser<Input, (UInt8, UInt8, UInt8), MatchByte.Error> = Parser.Machine.build { builder in
            let a = Parser.Machine.leaf(MatchByte(expected: 65), in: &builder)
            let b = Parser.Machine.leaf(MatchByte(expected: 66), in: &builder)
            let c = Parser.Machine.leaf(MatchByte(expected: 67), in: &builder)
            let ab = Parser.Machine.sequence(a, b, combine: { ($0, $1) }, in: &builder)
            return Parser.Machine.sequence(ab, c, combine: { ($0.0, $0.1, $1) }, in: &builder)
        }

        var ctx = parser.parse.incremental
        var input = Input([65, 66, 67])
        _ = try ctx(&input)

        let countBefore = ctx.count

        ctx.invalidate(.init(start: 1, oldEnd: 1, newEnd: 2))
        #expect(ctx.count < countBefore)
    }
}

// MARK: - Integration

extension ParserMachineIncrementalTests.Integration {
    @Test
    func `oneOf with memoization caches failed alternatives`() throws {
        let parser: Parser.Machine.Parser<Input, UInt8, MatchByte.Error> = Parser.Machine.build { builder in
            let a = Parser.Machine.leaf(MatchByte(expected: 65), in: &builder)
            let b = Parser.Machine.leaf(MatchByte(expected: 66), in: &builder)
            let c = Parser.Machine.leaf(MatchByte(expected: 67), in: &builder)
            return Parser.Machine.oneOf([a, b, c], in: &builder)
        }

        var ctx = parser.parse.incremental

        var input = Input([67])
        let result = try ctx(&input)

        #expect(result == 67)
        #expect(ctx.count >= 3)
    }

    @Test
    func `recursive grammar with memoization`() throws {
        let parser: Parser.Machine.Parser<Input, Int, TestError> = Parser.Machine.recursive(maxDepth: 100) { builder, selfRef in
            let empty = Parser.Machine.pure(0, in: &builder)
            let open = Parser.Machine.leaf(OpenParen(), mapError: { _ in TestError.openParen }, in: &builder)
            let close = Parser.Machine.leaf(CloseParen(), mapError: { _ in TestError.closeParen }, in: &builder)
            let inner = selfRef.expression(in: &builder)

            let recursive = Parser.Machine.sequence(open, inner, combine: { (_: Void, depth: Int) in depth }, in: &builder)
            let withClose = Parser.Machine.sequence(recursive, close, combine: { (depth: Int, _: Void) in depth + 1 }, in: &builder)

            return Parser.Machine.oneOf([withClose, empty], in: &builder)
        }

        var ctx = parser.parse.incremental

        var input = makeInput("((()))")
        let depth = try ctx(&input)

        #expect(depth == 3)
        #expect(ctx.count > 0)
    }
}
