import Parser_Machine_Combinator_Primitives
import Parser_Machine_Compile_Primitives
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

func makeInput(_ bytes: [UInt8]) -> Input {
    Input(bytes)
}
