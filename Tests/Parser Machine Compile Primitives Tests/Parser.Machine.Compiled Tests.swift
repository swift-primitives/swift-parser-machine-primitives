import Testing
import Parser_Machine_Compile_Primitives
import Parser_Machine_Combinator_Primitives

@Suite("Parser.Machine.Compiled")
struct ParserMachineCompiledTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: - Unit

extension ParserMachineCompiledTests.Unit {
    @Test
    func `compiled parser lazily compiles on first parse`() throws {
        let compiled = Parser.Machine.Compiled(source: ByteParser(), witness: .leaf)

        var input = Input([65])
        let result = try compiled.parse(&input)
        #expect(result == 65)
    }

    @Test
    func `compiled parser reuses cached program on subsequent parses`() throws {
        let compiled = Parser.Machine.Compiled(source: ByteParser(), witness: .leaf)

        var input1 = Input([65])
        let result1 = try compiled.parse(&input1)

        var input2 = Input([66])
        let result2 = try compiled.parse(&input2)

        #expect(result1 == 65)
        #expect(result2 == 66)
    }

    @Test
    func `prepared from compiled returns immutable parser`() throws {
        let compiled = Parser.Machine.Compiled(source: ByteParser(), witness: .leaf)
        let prepared = compiled.prepared()

        var input = Input([42])
        let result = try prepared.parse(&input)
        #expect(result == 42)
    }
}
