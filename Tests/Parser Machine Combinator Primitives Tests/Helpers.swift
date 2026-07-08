import Parser_Machine_Combinator_Primitives
import Parser_Primitives_Test_Support

typealias Input = Parser.Test.Input

struct ByteParser: Parser.`Protocol`, Sendable {}

extension ByteParser {
    enum Error: Swift.Error, Sendable {
        case endOfInput
    }

    func parse(_ input: inout Input) throws(Error) -> UInt8 {
        guard let byte = input.first else {
            throw .endOfInput
        }
        // swift-format-ignore: NeverUseForceTry
        try! input.advance()
        return byte
    }
}

struct MatchByte: Parser.`Protocol`, Sendable {
    let expected: UInt8
}

extension MatchByte {
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
        // swift-format-ignore: NeverUseForceTry
        try! input.advance()
        return byte
    }
}

func makeInput(_ bytes: [UInt8]) -> Input {
    Input(bytes)
}

func makeInput(_ string: Swift.String) -> Input {
    Input(utf8: string)
}

extension Input {
    func remainingBytes() -> [UInt8] {
        var copy = self
        var result: [UInt8] = []
        while !copy.isEmpty {
            // swift-format-ignore: NeverUseForceTry
            result.append(try! copy.advance())
        }
        return result
    }
}
