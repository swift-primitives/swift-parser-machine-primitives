import Parser_Primitives_Test_Support
import Testing
import Parser_Machine_Combinator_Primitives

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

// MARK: - XML-like Grammar Helpers

private struct XMLElement: Sendable, Equatable {
    var name: String
    var content: [XMLContent]
}

private enum XMLContent: Sendable, Equatable {
    case element(XMLElement)
}

private struct OpenBracket: Parser.`Protocol`, Sendable {
    enum Error: Swift.Error, Sendable { case expected }
    func parse(_ input: inout Input) throws(Error) -> Void {
        guard input.first == UInt8(ascii: "<") else { throw .expected }
        try! input.advance()
    }
}

private struct CloseBracket: Parser.`Protocol`, Sendable {
    enum Error: Swift.Error, Sendable { case expected }
    func parse(_ input: inout Input) throws(Error) -> Void {
        guard input.first == UInt8(ascii: ">") else { throw .expected }
        try! input.advance()
    }
}

private struct SlashClose: Parser.`Protocol`, Sendable {
    enum Error: Swift.Error, Sendable { case expected }
    func parse(_ input: inout Input) throws(Error) -> Void {
        guard input.first == UInt8(ascii: "/") else { throw .expected }
        try! input.advance()
        guard input.first == UInt8(ascii: ">") else { throw .expected }
        try! input.advance()
    }
}

// MARK: - TryMap Grammar Helpers

private struct StartTagOutput: Sendable {
    var isEmpty: Bool
}

private struct ParseOpen: Parser.`Protocol`, Sendable {
    enum Error: Swift.Error, Sendable { case expected }
    func parse(_ input: inout Input) throws(Error) -> StartTagOutput {
        guard input.first == UInt8(ascii: "<") else { throw .expected }
        try! input.advance()
        if input.first == UInt8(ascii: "/") {
            try! input.advance()
            guard input.first == UInt8(ascii: ">") else { throw .expected }
            try! input.advance()
            return StartTagOutput(isEmpty: true)
        } else {
            return StartTagOutput(isEmpty: false)
        }
    }
}

private struct ParseClose: Parser.`Protocol`, Sendable {
    enum Error: Swift.Error, Sendable { case expected }
    func parse(_ input: inout Input) throws(Error) -> Void {
        guard input.first == UInt8(ascii: ">") else { throw .expected }
        try! input.advance()
    }
}

// MARK: - Suite

@Suite("Parser.Machine.Recursive")
struct ParserMachineRecursiveTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: - Unit

extension ParserMachineRecursiveTests.Unit {
    @Test
    func `balanced parentheses parses three levels`() throws {
        let parser = balancedParenParser(maxDepth: 1000)

        var input = makeInput("((()))")
        let depth = try parser.parse(&input)
        #expect(depth == 3)
        #expect(input.first == nil)
    }

    @Test
    func `balanced parentheses parses 100 levels`() throws {
        let parser = balancedParenParser(maxDepth: 1000)

        var bytes: Swift.Array<UInt8> = []
        for _ in 0..<100 { bytes.append(UInt8(ascii: "(")) }
        for _ in 0..<100 { bytes.append(UInt8(ascii: ")")) }

        var input = makeInput(bytes)
        let depth = try parser.parse(&input)
        #expect(depth == 100)
        #expect(input.first == nil)
    }

    @Test
    func `build creates non-recursive parser`() throws {
        let parser: Parser.Machine.Parser<Input, UInt8, ByteParser.Error> = Parser.Machine.build { builder in
            Parser.Machine.leaf(ByteParser(), in: &builder)
        }

        var input = Input([42])
        let result = try parser.parse(&input)
        #expect(result == 42)
    }
}

// MARK: - Integration

extension ParserMachineRecursiveTests.Integration {
    @Test
    func `deep nesting 2000 levels without stack overflow`() throws {
        let parser = balancedParenParser(maxDepth: 10000)

        var bytes: Swift.Array<UInt8> = []
        for _ in 0..<2000 { bytes.append(UInt8(ascii: "(")) }
        for _ in 0..<2000 { bytes.append(UInt8(ascii: ")")) }

        var input = makeInput(bytes)
        let depth = try parser.parse(&input)
        #expect(depth == 2000)
        #expect(input.first == nil)
    }

    @Test
    func `deep nesting 5000 levels without stack overflow`() throws {
        let parser = balancedParenParser(maxDepth: 10000)

        var bytes: Swift.Array<UInt8> = []
        for _ in 0..<5000 { bytes.append(UInt8(ascii: "(")) }
        for _ in 0..<5000 { bytes.append(UInt8(ascii: ")")) }

        var input = makeInput(bytes)
        let depth = try parser.parse(&input)
        #expect(depth == 5000)
        #expect(input.first == nil)
    }

    @Test
    func `deep nesting with complex types 1000 levels`() throws {
        let parser: Parser.Machine.Parser<Input, XMLElement, ParenError> = Parser.Machine.recursive(maxDepth: 2000) { builder, selfRef in
            let open = Parser.Machine.leaf(OpenBracket(), mapError: { _ in ParenError.openParen }, in: &builder)
            let close = Parser.Machine.leaf(CloseBracket(), mapError: { _ in ParenError.closeParen }, in: &builder)
            let slashClose = Parser.Machine.leaf(SlashClose(), mapError: { _ in ParenError.closeParen }, in: &builder)

            let elementContent = selfRef.expression(in: &builder)
                .map({ XMLContent.element($0) }, in: &builder)

            let content = Parser.Machine.many(elementContent, in: &builder)

            let openWithContent = Parser.Machine.sequence(open, content, combine: { (_: Void, c: [XMLContent]) in c }, in: &builder)
            let nonEmpty = Parser.Machine.sequence(openWithContent, close, combine: { (contents: [XMLContent], _: Void) in
                XMLElement(name: "e", content: contents)
            }, in: &builder)

            let emptyElement = Parser.Machine.sequence(open, slashClose, combine: { (_: Void, _: Void) in
                XMLElement(name: "e", content: [])
            }, in: &builder)

            return Parser.Machine.oneOf([nonEmpty, emptyElement], in: &builder)
        }

        var bytes: Swift.Array<UInt8> = []
        for _ in 0..<1000 { bytes.append(UInt8(ascii: "<")) }
        bytes.append(UInt8(ascii: "/"))
        bytes.append(UInt8(ascii: ">"))
        for _ in 0..<999 { bytes.append(UInt8(ascii: ">")) }

        var input = makeInput(bytes)
        let result = try parser.parse(&input)
        #expect(result.name == "e")
        #expect(input.isEmpty)
    }

    @Test
    func `deep nesting with tryMap disambiguation 50 levels`() throws {
        let parser: Parser.Machine.Parser<Input, XMLElement, ParenError> = Parser.Machine.recursive(maxDepth: 100) { builder, selfRef in
            let startTag = Parser.Machine.leaf(ParseOpen(), mapError: { _ in ParenError.openParen }, in: &builder)
            let endTag = Parser.Machine.leaf(ParseClose(), mapError: { _ in ParenError.closeParen }, in: &builder)

            let emptyElement = startTag.tryMap({ (start: StartTagOutput) throws(ParenError) -> XMLElement in
                guard start.isEmpty else { throw ParenError.openParen }
                return XMLElement(name: "e", content: [])
            }, in: &builder)

            let openTag = startTag.tryMap({ (start: StartTagOutput) throws(ParenError) -> StartTagOutput in
                guard !start.isEmpty else { throw ParenError.closeParen }
                return start
            }, in: &builder)

            let elementContent = selfRef.expression(in: &builder)
                .map({ XMLContent.element($0) }, in: &builder)

            let content = Parser.Machine.many(elementContent, in: &builder)

            let withContent = Parser.Machine.sequence(openTag, content, combine: { (_: StartTagOutput, c: [XMLContent]) in c }, in: &builder)
            let nonEmptyElement = Parser.Machine.sequence(withContent, endTag, combine: { (contents: [XMLContent], _: Void) in
                XMLElement(name: "e", content: contents)
            }, in: &builder)

            return Parser.Machine.oneOf([emptyElement, nonEmptyElement], in: &builder)
        }

        var bytes: Swift.Array<UInt8> = []
        for _ in 0..<50 { bytes.append(UInt8(ascii: "<")) }
        bytes.append(UInt8(ascii: "/"))
        bytes.append(UInt8(ascii: ">"))
        for _ in 0..<49 { bytes.append(UInt8(ascii: ">")) }

        var input = makeInput(bytes)
        let result = try parser.parse(&input)
        #expect(result.name == "e")
        #expect(input.isEmpty)
    }
}
