package import Machine_Primitives
import Parser_Primitives
package import Tagged_Primitives
package import Parser_Machine_Program_Primitives

extension Parser.Machine {
    package enum Failure {}
}

extension Parser.Machine.Failure {
    package enum Recovery {
        package enum Tag {}

        package typealias ID = Tagged<Tag, Ordinal>

        case continueWith(ID)
        case handleReady(Parser.Machine.Value.Handle)
        case propagate
    }
}
