import Parser_Primitives_Test_Support
import Testing
import Parser_Machine_Combinator_Primitives

@Suite("Parser.Machine.Combinators")
struct ParserMachineCombinatorTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: - Unit

extension ParserMachineCombinatorTests.Unit {
    @Test
    func `pure always succeeds with given value`() throws {
        let parser: Parser.Machine.Parser<Input, Int, ByteParser.Error> = Parser.Machine.build { builder in
            Parser.Machine.pure(42, in: &builder)
        }

        var input = Input([1, 2, 3])
        let result = try parser.parse(&input)
        #expect(result == 42)
        #expect(input.remainingBytes() == [1, 2, 3])
    }

    @Test
    func `leaf wraps parser as machine node`() throws {
        let parser: Parser.Machine.Parser<Input, UInt8, ByteParser.Error> = Parser.Machine.build { builder in
            Parser.Machine.leaf(ByteParser(), in: &builder)
        }

        var input = Input([65, 66, 67])
        let result = try parser.parse(&input)
        #expect(result == 65)
        #expect(input.remainingBytes() == [66, 67])
    }

    @Test
    func `map transforms output`() throws {
        let parser: Parser.Machine.Parser<Input, Int, ByteParser.Error> = Parser.Machine.build { builder in
            let byte = Parser.Machine.leaf(ByteParser(), in: &builder)
            return byte.map({ Int($0) * 2 }, in: &builder)
        }

        var input = Input([10])
        let result = try parser.parse(&input)
        #expect(result == 20)
    }

    @Test
    func `sequence combines two parsers`() throws {
        let parser: Parser.Machine.Parser<Input, (UInt8, UInt8), ByteParser.Error> = Parser.Machine.build { builder in
            let first = Parser.Machine.leaf(ByteParser(), in: &builder)
            let second = Parser.Machine.leaf(ByteParser(), in: &builder)
            return Parser.Machine.sequence(first, second, combine: { ($0, $1) }, in: &builder)
        }

        var input = Input([1, 2, 3])
        let result = try parser.parse(&input)
        #expect(result.0 == 1)
        #expect(result.1 == 2)
        #expect(input.remainingBytes() == [3])
    }

    @Test
    func `oneOf selects first matching alternative`() throws {
        let parser: Parser.Machine.Parser<Input, UInt8, MatchByte.Error> = Parser.Machine.build { builder in
            let a = Parser.Machine.leaf(MatchByte(expected: 65), in: &builder)
                .map({ $0 }, in: &builder)
            let b = Parser.Machine.leaf(MatchByte(expected: 66), in: &builder)
                .map({ $0 }, in: &builder)
            return Parser.Machine.oneOf([a, b], in: &builder)
        }

        var input = Input([65])
        let result = try parser.parse(&input)
        #expect(result == 65)
    }

    @Test
    func `oneOf falls through to second alternative`() throws {
        let parser: Parser.Machine.Parser<Input, UInt8, MatchByte.Error> = Parser.Machine.build { builder in
            let a = Parser.Machine.leaf(MatchByte(expected: 65), in: &builder)
                .map({ $0 }, in: &builder)
            let b = Parser.Machine.leaf(MatchByte(expected: 66), in: &builder)
                .map({ $0 }, in: &builder)
            return Parser.Machine.oneOf([a, b], in: &builder)
        }

        var input = Input([66])
        let result = try parser.parse(&input)
        #expect(result == 66)
    }

    @Test
    func `many collects zero or more occurrences`() throws {
        let parser: Parser.Machine.Parser<Input, [UInt8], MatchByte.Error> = Parser.Machine.build { builder in
            let byte = Parser.Machine.leaf(MatchByte(expected: 65), in: &builder)
                .map({ $0 }, in: &builder)
            return Parser.Machine.many(byte, in: &builder)
        }

        var input = Input([65, 65, 65, 66])
        let result = try parser.parse(&input)
        #expect(result == [65, 65, 65])
        #expect(input.remainingBytes() == [66])
    }

    @Test
    func `optional returns value on success`() throws {
        let parser: Parser.Machine.Parser<Input, UInt8?, MatchByte.Error> = Parser.Machine.build { builder in
            let byte = Parser.Machine.leaf(MatchByte(expected: 65), in: &builder)
                .map({ $0 }, in: &builder)
            return Parser.Machine.optional(byte, in: &builder)
        }

        var input = Input([65, 66])
        let result = try parser.parse(&input)
        #expect(result == 65)
        #expect(input.remainingBytes() == [66])
    }
}

// MARK: - Edge Cases

extension ParserMachineCombinatorTests.EdgeCase {
    @Test
    func `many returns empty array when no matches`() throws {
        let parser: Parser.Machine.Parser<Input, [UInt8], MatchByte.Error> = Parser.Machine.build { builder in
            let byte = Parser.Machine.leaf(MatchByte(expected: 0xFF), in: &builder)
                .map({ $0 }, in: &builder)
            return Parser.Machine.many(byte, in: &builder)
        }

        var input = Input([1, 2, 3])
        let result = try parser.parse(&input)
        #expect(result.isEmpty)
        #expect(input.remainingBytes() == [1, 2, 3])
    }

    @Test
    func `optional returns nil and restores input on failure`() throws {
        let parser: Parser.Machine.Parser<Input, UInt8?, MatchByte.Error> = Parser.Machine.build { builder in
            let byte = Parser.Machine.leaf(MatchByte(expected: 65), in: &builder)
                .map({ $0 }, in: &builder)
            return Parser.Machine.optional(byte, in: &builder)
        }

        var input = Input([66, 67])
        let result = try parser.parse(&input)
        #expect(result == nil)
        #expect(input.remainingBytes() == [66, 67])
    }

    @Test
    func `oneOf throws when all alternatives fail`() throws {
        let parser: Parser.Machine.Parser<Input, UInt8, MatchByte.Error> = Parser.Machine.build { builder in
            let a = Parser.Machine.leaf(MatchByte(expected: 65), in: &builder)
                .map({ $0 }, in: &builder)
            let b = Parser.Machine.leaf(MatchByte(expected: 66), in: &builder)
                .map({ $0 }, in: &builder)
            return Parser.Machine.oneOf([a, b], in: &builder)
        }

        var input = Input([67])
        #expect(throws: MatchByte.Error.self) {
            _ = try parser.parse(&input)
        }
    }
}
