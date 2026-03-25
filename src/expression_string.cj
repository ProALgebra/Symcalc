package symcalc
import std.collection.*

extend<A> Expression_<A> <: ToString where A <: ToString {
    public func toString(): String {
        match (this) {
            case Constant(value) => "Constant(${value})"
            case Variable(name) => "Variable(${name})"
            case Add(constantPart, terms) =>
                "Add(constant=${constantPart}, terms=${terms})"
            case Multiply(constantPart, terms) =>
                "Multiply(constant=${constantPart}, terms=${terms})"
            case Function(functionName, args) =>
                var argsString = "["
                var first = true
                for (arg in args) {
                    if (!first) {
                        argsString += ", "
                    }
                    argsString += "${arg}"
                    first = false
                }
                argsString += "]"
                "Function(name=${functionName}, args=${argsString})"
        }
    }
}
