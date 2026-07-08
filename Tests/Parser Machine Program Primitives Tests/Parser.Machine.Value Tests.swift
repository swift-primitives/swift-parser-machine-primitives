import Machine_Value_Primitives
import Parser_Machine_Program_Primitives
import Testing

// MARK: - Value

@Suite("Parser.Machine.Value")
struct ParserMachineValueTests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension ParserMachineValueTests.Unit {
    @Test
    func `make and subscript preserves integer value`() {
        let value = Parser.Machine.Value.make(42)
        #expect(value[as: Int.self] == 42)
    }

    @Test
    func `make and subscript preserves string value`() {
        let value = Parser.Machine.Value.make("hello")
        #expect(value[as: String.self] == "hello")
    }
}

extension ParserMachineValueTests.`Edge Case` {
    @Test
    func `subscript with wrong type traps`() {
        let value = Parser.Machine.Value.make(42)
        #expect(value[as: Int.self] == 42)
    }
}
