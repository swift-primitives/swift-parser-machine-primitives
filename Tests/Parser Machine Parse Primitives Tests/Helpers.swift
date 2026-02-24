import Parser_Machine_Parse_Primitives
import Parser_Machine_Combinator_Primitives
import Parser_Primitives_Test_Support

typealias Input = ByteInput

struct ByteParser: Parser.`Protocol`, Sendable {
    enum Error: Swift.Error, Sendable {
        case endOfInput
    }

    func parse(_ input: inout Input) throws(Error) -> UInt8 {
        guard let byte = input.first else {
            throw .endOfInput
        }
        try! input.advance()
        return byte
    }
}

struct MatchByte: Parser.`Protocol`, Sendable {
    let expected: UInt8

    enum Error: Swift.Error, Sendable {
        case mismatch(expected: UInt8, actual: UInt8?)
    }

    func parse(_ input: inout Input) throws(Error) -> UInt8 {
        guard let byte = input.first else {
            throw .mismatch(expected: expected, actual: nil)
        }
        guard byte == expected else {
            throw .mismatch(expected: expected, actual: byte)
        }
        try! input.advance()
        return byte
    }
}

func makeInput(_ bytes: Swift.Array<UInt8>) -> Input {
    Input(bytes)
}

func makeInput(_ string: Swift.String) -> Input {
    Input(utf8: string)
}
