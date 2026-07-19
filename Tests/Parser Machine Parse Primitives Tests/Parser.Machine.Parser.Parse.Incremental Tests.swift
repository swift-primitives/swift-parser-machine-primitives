import Parser_Machine_Combinator_Primitives
import Parser_Machine_Parse_Primitives
import Parser_Primitives_Test_Support
import Testing

// MARK: - Helpers for Recursive Grammar

private struct OpenParen: Parser.`Protocol`, Sendable {}

extension OpenParen {
    enum Error: Swift.Error, Sendable { case expected }
    func parse(_ input: inout Input) throws(Error) {
        guard input.first == UInt8(ascii: "(") else { throw .expected }
        // swift-format-ignore: NeverUseForceTry
        try! input.advance()
    }
}

private struct CloseParen: Parser.`Protocol`, Sendable {}

extension CloseParen {
    enum Error: Swift.Error, Sendable { case expected }
    func parse(_ input: inout Input) throws(Error) {
        guard input.first == UInt8(ascii: ")") else { throw .expected }
        // swift-format-ignore: NeverUseForceTry
        try! input.advance()
    }
}

private enum TestError: Swift.Error, Sendable {
    case openParen
    case closeParen
}

// MARK: - Suite

@Suite
struct `Parser.Machine.Parser.Parse.Incremental Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: - Unit

extension `Parser.Machine.Parser.Parse.Incremental Tests`.Unit {
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

extension `Parser.Machine.Parser.Parse.Incremental Tests`.`Edge Case` {
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

    // MARK: F-001 regression

    @Test
    func `re-parsing previously-failed input throws the same typed failure instead of crashing`() throws {
        let parser: Parser.Machine.Parser<Input, UInt8, MatchByte.Error> = Parser.Machine.build { builder in
            Parser.Machine.leaf(MatchByte(expected: 65), in: &builder)
        }

        var ctx = parser.parse.incremental

        var input1 = Input([90])
        #expect(throws: MatchByte.Error.self) {
            _ = try ctx(&input1)
        }

        // Same failing content again: this hits the memoized `.failure` entry
        // cached by the first attempt. It must re-throw the typed failure,
        // not crash the process with "Cached failure with no recovery".
        var input2 = Input([90])
        #expect(throws: MatchByte.Error.self) {
            _ = try ctx(&input2)
        }
    }

    // MARK: F-002 regression

    @Test
    func `invalidate from position drops success entries whose span crosses the cutoff`() throws {
        let parser: Parser.Machine.Parser<Input, [UInt8], ByteParser.Error> = Parser.Machine.build { builder in
            let byte = Parser.Machine.leaf(ByteParser(), in: &builder)
            return Parser.Machine.many(byte, in: &builder)
        }

        var ctx = parser.parse.incremental
        var input1 = Input([65, 66, 67, 68])
        let result1 = try ctx(&input1)
        #expect(result1 == [65, 66, 67, 68])

        // The whole-parse entry spans [0, 4) and crosses this cutoff, so it
        // must be dropped even though its *start* (0) is before position 2 —
        // otherwise the stale entry is reused below and the changed bytes at
        // positions 2 and 3 are never examined.
        ctx.invalidate(from: 2)

        var input2 = Input([65, 66, 99, 100])
        let result2 = try ctx(&input2)

        #expect(result2 == [65, 66, 99, 100])
    }

    @Test
    func `re-parse after insert edit matches a fresh parse of the edited content`() throws {
        let parser: Parser.Machine.Parser<Input, [UInt8], ByteParser.Error> = Parser.Machine.build { builder in
            let byte = Parser.Machine.leaf(ByteParser(), in: &builder)
            return Parser.Machine.many(byte, in: &builder)
        }

        var ctx = parser.parse.incremental
        var original = Input([65, 66, 67, 68, 69])
        _ = try ctx(&original)

        // Insert one byte at the front: "ABCDE" -> "XABCDE".
        ctx.invalidate(.init(start: 0, oldEnd: 0, newEnd: 1))
        var edited = Input([88, 65, 66, 67, 68, 69])
        let incrementalResult = try ctx(&edited)

        var fresh = Input([88, 65, 66, 67, 68, 69])
        let freshResult = try parser.parse(&fresh)

        #expect(incrementalResult == freshResult)
    }

    @Test
    func `re-parse after delete edit matches a fresh parse of the edited content`() throws {
        let parser: Parser.Machine.Parser<Input, [UInt8], ByteParser.Error> = Parser.Machine.build { builder in
            let byte = Parser.Machine.leaf(ByteParser(), in: &builder)
            return Parser.Machine.many(byte, in: &builder)
        }

        var ctx = parser.parse.incremental
        var original = Input([65, 66, 67, 68, 69])
        _ = try ctx(&original)

        // Delete the byte at position 1: "ABCDE" -> "ACDE".
        ctx.invalidate(.delete(from: 1, to: 2))
        var edited = Input([65, 67, 68, 69])
        let incrementalResult = try ctx(&edited)

        var fresh = Input([65, 67, 68, 69])
        let freshResult = try parser.parse(&fresh)

        #expect(incrementalResult == freshResult)
    }

    @Test
    func `re-parse after replace edit matches a fresh parse of the edited content`() throws {
        let parser: Parser.Machine.Parser<Input, [UInt8], ByteParser.Error> = Parser.Machine.build { builder in
            let byte = Parser.Machine.leaf(ByteParser(), in: &builder)
            return Parser.Machine.many(byte, in: &builder)
        }

        var ctx = parser.parse.incremental
        var original = Input([65, 66, 67, 68, 69])
        _ = try ctx(&original)

        // Replace positions [1, 3) ("BC") with a single byte "Z": "ABCDE" -> "AZDE".
        ctx.invalidate(.init(start: 1, oldEnd: 3, newEnd: 2))
        var edited = Input([65, 90, 68, 69])
        let incrementalResult = try ctx(&edited)

        var fresh = Input([65, 90, 68, 69])
        let freshResult = try parser.parse(&fresh)

        #expect(incrementalResult == freshResult)
    }

    // MARK: F-004 regression (memoized interpreter)

    @Test
    func `many under memoization terminates when child succeeds without consuming input`() throws {
        let parser: Parser.Machine.Parser<Input, [Int], MatchByte.Error> = Parser.Machine.build { builder in
            let p = Parser.Machine.pure(7, in: &builder)
            return Parser.Machine.many(p, in: &builder)
        }

        var ctx = parser.parse.incremental
        var input = Input([65, 66, 67])
        let result = try ctx(&input)
        #expect(result == [7])
    }
}

// MARK: - Integration

extension `Parser.Machine.Parser.Parse.Incremental Tests`.Integration {
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

    @Test
    func `fails then edit invalidates cached failure then re-parse succeeds`() throws {
        let parser: Parser.Machine.Parser<Input, UInt8, MatchByte.Error> = Parser.Machine.build { builder in
            Parser.Machine.leaf(MatchByte(expected: 65), in: &builder)
        }

        var ctx = parser.parse.incremental

        var input1 = Input([90])
        #expect(throws: MatchByte.Error.self) {
            _ = try ctx(&input1)
        }

        // Replace the single byte with the expected one, invalidate, re-parse.
        ctx.invalidate(.init(start: 0, oldEnd: 1, newEnd: 1))
        var input2 = Input([65])
        let result = try ctx(&input2)
        #expect(result == 65)
    }
}
