import Parser_Machine_Combinator_Primitives
import Parser_Machine_Compile_Primitives
import Parser_Primitives_Test_Support

typealias Input = ByteInput

struct ByteParser: Parser.`Protocol`, Sendable {
    enum Error: Swift.Error, Sendable {
        case endOfInput
    }

    func parse(_ input: inout Input) throws(ByteParser.Error) -> UInt8 {
        guard let byte = input.first else {
            throw .endOfInput
        }
        try! input.advance()
        return byte
    }
}

func makeInput(_ bytes: Swift.Array<UInt8>) -> Input {
    Input(bytes)
}
