package symcalc
import std.collection.*

extend<A> Expression_<A> <: ToString
    where A <: Scalar<A> & Comparable<A> & Hashable & ToString & Equatable<A> {
    func precedence(expr: Expression_<A>): Int64 {
        match (expr) {
            case Add(_, _) => 1
            case Multiply(_, _) => 2
            case Function(functionName, args) =>
                if (functionName == "pow" && args.size == 2) {
                    3
                } else {
                    4
                }
            case _ => 4
        }
    }

    func isNegative(value: A): Bool {
        value.compare(A.zero()) == Ordering.LT
    }

    func negate(value: A): A {
        A.mul(value, A.fromInt(-1))
    }

    func inParens(text: String): String {
        "(${text})"
    }

    func inLatexParens(text: String): String {
        "\\left(${text}\\right)"
    }

    func formatPretty(expr: Expression_<A>, parentPrecedence: Int64): String {
        let currentPrecedence = precedence(expr)
        let rendered = match (expr) {
            case Constant(value) => "${value}"
            case Variable(name) => name
            case Add(constantPart, terms) => formatAddPretty(constantPart, terms)
            case Multiply(constantPart, terms) => formatMultiplyPretty(constantPart, terms)
            case Function(functionName, args) => formatFunctionPretty(functionName, args)
        }
        if (currentPrecedence < parentPrecedence) {
            inParens(rendered)
        } else {
            rendered
        }
    }

    func formatFunctionPretty(functionName: String, args: ArrayList<Expression_<A>>): String {
        var renderedArgs = ArrayList<String>([])
        for (arg in args) {
            renderedArgs.add(formatPretty(arg, 0))
        }
        FunctionRules<A>().renderFunctionPretty(functionName, renderedArgs)
    }

    func appendSignedPart(
        result: String,
        isFirst: Bool,
        negative: Bool,
        body: String
    ): String {
        if (isFirst) {
            if (negative) {
                "-${body}"
            } else {
                body
            }
        } else {
            if (negative) {
                "${result} - ${body}"
            } else {
                "${result} + ${body}"
            }
        }
    }

    func formatAddPretty(
        constantPart: A,
        terms: HashMap<Expression_<A>, A>
    ): String {
        var result = ""
        var hasPart = false

        if (!A.isZero(constantPart)) {
            let negative = isNegative(constantPart)
            let absValue = if (negative) { negate(constantPart) } else { constantPart }
            result = appendSignedPart(result, true, negative, "${absValue}")
            hasPart = true
        }

        let entries = this.sortedEntries(terms)
        for ((term, coefficient) in entries) {
            if (A.isZero(coefficient)) {
                continue
            }
            let negative = isNegative(coefficient)
            let absCoefficient = if (negative) { negate(coefficient) } else { coefficient }
            let termText = formatPretty(term, 2)
            let body = if (absCoefficient.compare(A.one()) == Ordering.EQ) {
                termText
            } else {
                "${absCoefficient} * ${termText}"
            }
            result = appendSignedPart(result, !hasPart, negative, body)
            hasPart = true
        }

        if (!hasPart) {
            "0"
        } else {
            result
        }
    }

    func formatMultiplyPretty(
        constantPart: A,
        terms: HashMap<Expression_<A>, A>
    ): String {
        if (A.isZero(constantPart)) {
            return "0"
        }

        var factors = ArrayList<String>([])
        let entries = this.sortedEntries(terms)
        for ((term, exponent) in entries) {
            if (A.isZero(exponent)) {
                continue
            }
            let baseText = formatPretty(term, 3)
            if (exponent.compare(A.one()) == Ordering.EQ) {
                factors.add(baseText)
            } else {
                factors.add("${baseText}^${inParens("${exponent}")}")
            }
        }

        if (factors.isEmpty()) {
            return "${constantPart}"
        }

        var result = ""
        var first = true

        if (constantPart.compare(A.one()) != Ordering.EQ) {
            if (constantPart.compare(A.fromInt(-1)) == Ordering.EQ) {
                result = "-"
            } else {
                result = "${constantPart}"
                first = false
            }
        }

        for (factor in factors) {
            if (first) {
                result += factor
                first = false
            } else {
                result += " * ${factor}"
            }
        }
        result
    }

    func formatLatex(expr: Expression_<A>, parentPrecedence: Int64): String {
        let currentPrecedence = precedence(expr)
        let rendered = match (expr) {
            case Constant(value) => "${value}"
            case Variable(name) => name
            case Add(constantPart, terms) => formatAddLatex(constantPart, terms)
            case Multiply(constantPart, terms) => formatMultiplyLatex(constantPart, terms)
            case Function(functionName, args) => formatFunctionLatex(functionName, args)
        }
        if (currentPrecedence < parentPrecedence) {
            inLatexParens(rendered)
        } else {
            rendered
        }
    }

    func formatFunctionLatex(functionName: String, args: ArrayList<Expression_<A>>): String {
        var renderedArgs = ArrayList<String>([])
        for (arg in args) {
            renderedArgs.add(formatLatex(arg, 0))
        }
        FunctionRules<A>().renderFunctionLatex(functionName, renderedArgs)
    }

    func formatAddLatex(
        constantPart: A,
        terms: HashMap<Expression_<A>, A>
    ): String {
        var result = ""
        var hasPart = false

        if (!A.isZero(constantPart)) {
            let negative = isNegative(constantPart)
            let absValue = if (negative) { negate(constantPart) } else { constantPart }
            result = appendSignedPart(result, true, negative, "${absValue}")
            hasPart = true
        }

        let entries = this.sortedEntries(terms)
        for ((term, coefficient) in entries) {
            if (A.isZero(coefficient)) {
                continue
            }
            let negative = isNegative(coefficient)
            let absCoefficient = if (negative) { negate(coefficient) } else { coefficient }
            let termText = formatLatex(term, 2)
            let body = if (absCoefficient.compare(A.one()) == Ordering.EQ) {
                termText
            } else {
                "${absCoefficient} \\cdot ${termText}"
            }
            result = appendSignedPart(result, !hasPart, negative, body)
            hasPart = true
        }

        if (!hasPart) {
            "0"
        } else {
            result
        }
    }

    func formatMultiplyLatex(
        constantPart: A,
        terms: HashMap<Expression_<A>, A>
    ): String {
        if (A.isZero(constantPart)) {
            return "0"
        }

        var factors = ArrayList<String>([])
        let entries = this.sortedEntries(terms)
        for ((term, exponent) in entries) {
            if (A.isZero(exponent)) {
                continue
            }
            let baseText = formatLatex(term, 3)
            if (exponent.compare(A.one()) == Ordering.EQ) {
                factors.add(baseText)
            } else {
                factors.add("${baseText}^{${exponent}}")
            }
        }

        if (factors.isEmpty()) {
            return "${constantPart}"
        }

        var result = ""
        var first = true

        if (constantPart.compare(A.one()) != Ordering.EQ) {
            if (constantPart.compare(A.fromInt(-1)) == Ordering.EQ) {
                result = "-"
            } else {
                result = "${constantPart}"
                first = false
            }
        }

        for (factor in factors) {
            if (first) {
                result += factor
                first = false
            } else {
                result += " \\cdot ${factor}"
            }
        }
        result
    }

    public func prettyPrint(): String {
        formatPretty(this, 0)
    }

    public func toLatex(): String {
        formatLatex(this, 0)
    }

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
