public import Machine_Primitives
import Parser_Primitives
public import Tagged_Primitives

extension Parser.Machine {
    /// Creates a leaf expression that wraps an existing parser.
    @inlinable
    public static func leaf<Input, Output, Failure, P>(
        _ parser: P,
        in builder: inout Builder<Input, Failure>
    ) -> Expression<Input, Failure, Output>
    where
        P: Parser_Primitives.Parser.`Protocol`,
        P.Input == Input,
        P.Output == Output,
        P.Failure == Failure,
        Input: Parser_Primitives.Parser.Input.`Protocol` & ~Copyable,
        Failure: Swift.Error & Sendable
    {
        let node = Node<Input, Failure>.leaf(
            Leaf { (input: inout Input) throws(Failure) -> Value in
                Value.make(try parser.parse(&input))
            }
        )
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }

    /// Creates a leaf expression that wraps an existing parser with error mapping.
    @inlinable
    public static func leaf<Input, Output, Failure, P>(
        _ parser: P,
        mapError: @escaping (P.Failure) -> Failure,
        in builder: inout Builder<Input, Failure>
    ) -> Expression<Input, Failure, Output>
    where
        P: Parser_Primitives.Parser.`Protocol`,
        P.Input == Input,
        P.Output == Output,
        Input: Parser_Primitives.Parser.Input.`Protocol` & ~Copyable,
        Failure: Swift.Error & Sendable
    {
        let node = Node<Input, Failure>.leaf(
            Leaf { (input: inout Input) throws(Failure) -> Value in
                do throws(P.Failure) {
                    return Value.make(try parser.parse(&input))
                } catch {
                    throw mapError(error)
                }
            }
        )
        let nodeID = builder.allocate(node)
        return Expression(node: nodeID)
    }
}
