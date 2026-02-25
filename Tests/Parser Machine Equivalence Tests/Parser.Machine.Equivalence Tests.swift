import Testing
import Parser_Machine_Combinator_Primitives
import Parser_Machine_Compile_Primitives

// MARK: - Test Suite Structure

@Suite("Parser.Machine.Equivalence")
struct ParserMachineEquivalenceTests {
    @Suite("Direct ≡ Compiled") struct DirectEqualsCompiled {}
    @Suite struct StackSafety {}
    @Suite struct Caching {}
}

// MARK: - Direct ≡ Compiled

extension ParserMachineEquivalenceTests.DirectEqualsCompiled {
    @Test
    func `leaf - single byte parse`() throws {
        // Direct
        let direct = ByteParser()

        // Compiled via Machine
        let machine: Parser.Machine.Parser<Input, UInt8, ByteParser.Error> = Parser.Machine.build { builder in
            Parser.Machine.leaf(ByteParser(), in: &builder)
        }

        var input1 = makeInput([65, 66])
        var input2 = makeInput([65, 66])

        let result1 = try direct.parse(&input1)
        let result2 = try machine.parse(&input2)

        #expect(result1 == result2)
        #expect(input1.remainingBytes() == input2.remainingBytes())
    }

    @Test
    func `map - byte to Int transformation`() throws {
        // Direct
        let direct = ByteParser()

        // Machine with map
        let machine: Parser.Machine.Parser<Input, Int, ByteParser.Error> = Parser.Machine.build { builder in
            let byte = Parser.Machine.leaf(ByteParser(), in: &builder)
            return byte.map({ Int($0) * 2 }, in: &builder)
        }

        var input1 = makeInput([10, 20])
        var input2 = makeInput([10, 20])

        let result1 = Int(try direct.parse(&input1)) * 2
        let result2 = try machine.parse(&input2)

        #expect(result1 == result2)
        #expect(input1.remainingBytes() == input2.remainingBytes())
    }

    @Test
    func `sequence - two sequential bytes`() throws {
        let machine: Parser.Machine.Parser<Input, (UInt8, UInt8), ByteParser.Error> = Parser.Machine.build { builder in
            let first = Parser.Machine.leaf(ByteParser(), in: &builder)
            let second = Parser.Machine.leaf(ByteParser(), in: &builder)
            return Parser.Machine.sequence(first, second, combine: { ($0, $1) }, in: &builder)
        }

        var input1 = makeInput([1, 2, 3])
        var input2 = makeInput([1, 2, 3])

        // Direct: two sequential parses
        let a1 = try ByteParser().parse(&input1)
        let b1 = try ByteParser().parse(&input1)

        // Machine: sequence combinator
        let result2 = try machine.parse(&input2)

        #expect(a1 == result2.0)
        #expect(b1 == result2.1)
        #expect(input1.remainingBytes() == input2.remainingBytes())
    }

    @Test
    func `oneOf - first match`() throws {
        let machine: Parser.Machine.Parser<Input, UInt8, MatchByte.Error> = Parser.Machine.build { builder in
            let a = Parser.Machine.leaf(MatchByte(expected: 65), in: &builder)
                .map({ $0 }, in: &builder)
            let b = Parser.Machine.leaf(MatchByte(expected: 66), in: &builder)
                .map({ $0 }, in: &builder)
            return Parser.Machine.oneOf([a, b], in: &builder)
        }

        var input = makeInput([65, 99])
        let result = try machine.parse(&input)

        #expect(result == 65)
        #expect(input.remainingBytes() == [99])
    }

    @Test
    func `oneOf - second match`() throws {
        let machine: Parser.Machine.Parser<Input, UInt8, MatchByte.Error> = Parser.Machine.build { builder in
            let a = Parser.Machine.leaf(MatchByte(expected: 65), in: &builder)
                .map({ $0 }, in: &builder)
            let b = Parser.Machine.leaf(MatchByte(expected: 66), in: &builder)
                .map({ $0 }, in: &builder)
            return Parser.Machine.oneOf([a, b], in: &builder)
        }

        var input = makeInput([66, 99])
        let result = try machine.parse(&input)

        #expect(result == 66)
        #expect(input.remainingBytes() == [99])
    }

    @Test
    func `oneOf - all fail`() {
        let machine: Parser.Machine.Parser<Input, UInt8, MatchByte.Error> = Parser.Machine.build { builder in
            let a = Parser.Machine.leaf(MatchByte(expected: 65), in: &builder)
                .map({ $0 }, in: &builder)
            let b = Parser.Machine.leaf(MatchByte(expected: 66), in: &builder)
                .map({ $0 }, in: &builder)
            return Parser.Machine.oneOf([a, b], in: &builder)
        }

        var input = makeInput([99])
        #expect(throws: MatchByte.Error.self) {
            _ = try machine.parse(&input)
        }
    }

    @Test
    func `many - zero matches`() throws {
        let machine: Parser.Machine.Parser<Input, [UInt8], MatchByte.Error> = Parser.Machine.build { builder in
            let byte = Parser.Machine.leaf(MatchByte(expected: 65), in: &builder)
                .map({ $0 }, in: &builder)
            return Parser.Machine.many(byte, in: &builder)
        }

        var input = makeInput([66, 67])
        let result = try machine.parse(&input)

        #expect(result.isEmpty)
        #expect(input.remainingBytes() == [66, 67])
    }

    @Test
    func `many - multiple matches`() throws {
        let machine: Parser.Machine.Parser<Input, [UInt8], MatchByte.Error> = Parser.Machine.build { builder in
            let byte = Parser.Machine.leaf(MatchByte(expected: 65), in: &builder)
                .map({ $0 }, in: &builder)
            return Parser.Machine.many(byte, in: &builder)
        }

        var input = makeInput([65, 65, 65, 66])
        let result = try machine.parse(&input)

        #expect(result == [65, 65, 65])
        #expect(input.remainingBytes() == [66])
    }

    @Test
    func `optional - present`() throws {
        let machine: Parser.Machine.Parser<Input, UInt8?, MatchByte.Error> = Parser.Machine.build { builder in
            let byte = Parser.Machine.leaf(MatchByte(expected: 65), in: &builder)
                .map({ $0 }, in: &builder)
            return Parser.Machine.optional(byte, in: &builder)
        }

        var input = makeInput([65, 66])
        let result = try machine.parse(&input)

        #expect(result == 65)
        #expect(input.remainingBytes() == [66])
    }

    @Test
    func `optional - absent restores input`() throws {
        let machine: Parser.Machine.Parser<Input, UInt8?, MatchByte.Error> = Parser.Machine.build { builder in
            let byte = Parser.Machine.leaf(MatchByte(expected: 65), in: &builder)
                .map({ $0 }, in: &builder)
            return Parser.Machine.optional(byte, in: &builder)
        }

        var input = makeInput([66, 67])
        let result = try machine.parse(&input)

        #expect(result == nil)
        #expect(input.remainingBytes() == [66, 67])
    }

    @Test
    func `recursive - nested parentheses depth 1`() throws {
        let machine = balancedParenParser(maxDepth: 100)

        var input = makeInput("()")
        let result = try machine.parse(&input)

        #expect(result == 1)
        #expect(input.first == nil)
    }

    @Test
    func `recursive - nested parentheses depth 5`() throws {
        let machine = balancedParenParser(maxDepth: 100)

        var input = makeInput("((((()))))") // depth 5
        let result = try machine.parse(&input)

        #expect(result == 5)
        #expect(input.first == nil)
    }

    @Test
    func `recursive - nested parentheses depth 100`() throws {
        let machine = balancedParenParser(maxDepth: 1000)

        var bytes: Swift.Array<UInt8> = []
        for _ in 0..<100 { bytes.append(UInt8(ascii: "(")) }
        for _ in 0..<100 { bytes.append(UInt8(ascii: ")")) }

        var input = makeInput(bytes)
        let result = try machine.parse(&input)

        #expect(result == 100)
        #expect(input.first == nil)
    }
}

// MARK: - Stack Safety

extension ParserMachineEquivalenceTests.StackSafety {
    @Test
    func `recursive parser at depth 1000 without stack overflow`() throws {
        let machine = balancedParenParser(maxDepth: 2000)

        var bytes: Swift.Array<UInt8> = []
        for _ in 0..<1000 { bytes.append(UInt8(ascii: "(")) }
        for _ in 0..<1000 { bytes.append(UInt8(ascii: ")")) }

        var input = makeInput(bytes)
        let result = try machine.parse(&input)

        #expect(result == 1000)
        #expect(input.first == nil)
    }
}

// MARK: - Caching

extension ParserMachineEquivalenceTests.Caching {
    @Test
    func `compiled parses same program twice with identical results`() throws {
        let compiled = Parser.Machine.Compiled(source: ByteParser(), witness: .leaf)

        var input1 = makeInput([42])
        let result1 = try compiled.parse(&input1)

        var input2 = makeInput([42])
        let result2 = try compiled.parse(&input2)

        #expect(result1 == result2)
    }

    @Test
    func `prepared from compiled yields same result`() throws {
        let compiled = Parser.Machine.Compiled(source: ByteParser(), witness: .leaf)
        let prepared = compiled.prepared()

        var input1 = makeInput([99])
        let result1 = try compiled.parse(&input1)

        var input2 = makeInput([99])
        let result2 = try prepared.parse(&input2)

        #expect(result1 == result2)
    }
}

// MARK: - Shared Grammar Helpers

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

private enum ParenError: Error, Sendable {
    case openParen
    case closeParen
}

private func balancedParenParser(
    maxDepth: Int
) -> Parser.Machine.Parser<Input, Int, ParenError> {
    Parser.Machine.recursive(maxDepth: maxDepth) { builder, selfRef in
        let empty = Parser.Machine.pure(0, in: &builder)
        let open = Parser.Machine.leaf(OpenParen(), mapError: { _ in ParenError.openParen }, in: &builder)
        let close = Parser.Machine.leaf(CloseParen(), mapError: { _ in ParenError.closeParen }, in: &builder)
        let inner = selfRef.expression(in: &builder)

        let recursive = Parser.Machine.sequence(open, inner, combine: { (_: Void, depth: Int) in depth }, in: &builder)
        let withClose = Parser.Machine.sequence(recursive, close, combine: { (depth: Int, _: Void) in depth + 1 }, in: &builder)

        return Parser.Machine.oneOf([withClose, empty], in: &builder)
    }
}
