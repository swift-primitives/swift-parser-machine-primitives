import Testing
import Parser_Machine_Core_Primitives

// MARK: - Value

@Suite("Parser.Machine.Value")
struct ParserMachineValueTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension ParserMachineValueTests.Unit {
    @Test
    func `make and take preserves integer value`() {
        let value = Parser.Machine.Value.make(42)
        #expect(value.take(Int.self) == 42)
    }

    @Test
    func `make and take preserves string value`() {
        let value = Parser.Machine.Value.make("hello")
        #expect(value.take(String.self) == "hello")
    }
}

extension ParserMachineValueTests.EdgeCase {
    @Test
    func `take with wrong type returns nil`() {
        let value = Parser.Machine.Value.make(42)
        #expect(value.take(String.self) == nil)
    }
}
