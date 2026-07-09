import Machine_Value_Primitives
import Parser_Machine_Program_Primitives
import Testing

// MARK: - Value

@Suite
struct `Parser.Machine.Value Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension `Parser.Machine.Value Tests`.Unit {
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

extension `Parser.Machine.Value Tests`.`Edge Case` {
    @Test
    func `subscript with wrong type traps`() {
        let value = Parser.Machine.Value.make(42)
        #expect(value[as: Int.self] == 42)
    }
}
