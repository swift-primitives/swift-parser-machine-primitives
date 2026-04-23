import Parser_Primitives
internal import Tagged_Primitives
internal import Machine_Primitives

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
