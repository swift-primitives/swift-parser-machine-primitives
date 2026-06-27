public import Input_Primitives
public import Machine_Primitives
import Parser_Primitives
public import Parser_Machine_Program_Primitives

extension Parser.Machine {
    /// A parser built from a defunctionalized program that runs without recursive call-stack growth.
    ///
    /// `Parser` is NOT `Sendable` per [MEM-SEND-013] Pattern B terminal direction.
    /// Consumers transport across isolation domains via `sending` at the
    /// program-transport boundary.
    public struct Parser<Input: Input_Primitives.Input.`Protocol` & ~Copyable, Output, Failure: Swift.Error>: Parser_Primitives.Parser.`Protocol` {
        package let program: Program<Input, Failure>

        package let root: Node<Input, Failure>.ID

        package init(program: Program<Input, Failure>, root: Node<Input, Failure>.ID) {
            self.program = program
            self.root = root
        }

        public func parse(_ input: inout Input) throws(Failure) -> Output {
            try Parser_Primitives.Parser.Machine.run(program: program, root: root, input: &input, as: Output.self)
        }
    }
}
