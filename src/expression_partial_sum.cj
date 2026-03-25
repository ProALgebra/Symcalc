package symcalc
import std.collection.*
import std.sort.*

class PartialSumRules<A> where A <: Scalar<A> & Comparable<A> & Hashable & ToString & Equatable<A> {
    func zeroExpression(): Expression_<A> {
        Add(A.zero(), HashMap<Expression_<A>, A>())
    }

    func normalizeArgs(args: ArrayList<Expression_<A>>): ArrayList<Expression_<A>> {
        var normalized = ArrayList<Expression_<A>>([])
        for (arg in args) {
            normalized.add(arg.toNormalForm())
        }
        normalized
    }

    func evaluateRangeSum(
        term: Expression_<A>,
        iteratorName: String,
        leftBound: A,
        rightBound: A
    ): Expression_<A> {
        if (leftBound.compare(rightBound) == Ordering.GT) {
            return this.zeroExpression()
        }

        var result = this.zeroExpression()
        var current = leftBound
        while (current.compare(rightBound) != Ordering.GT) {
            let iterationExpr = term
                .substituteVariable(iteratorName, Constant(current))
                .toNormalForm()
            result = (result + iterationExpr).toNormalForm()
            current = A.add(current, A.one())
        }
        result.toNormalForm()
    }

    func scalarToNonNegativeInt(value: A): Option<Int> {
        if (value.compare(A.zero()) == Ordering.LT) {
            return None
        }
        var asInt: Int = 0
        var current = A.zero()
        while (current.compare(value) == Ordering.LT) {
            current = A.add(current, A.one())
            asInt += 1
            if (asInt > 10000000) {
                return None
            }
        }
        if (current.compare(value) == Ordering.EQ) {
            Some(asInt)
        } else {
            None
        }
    }

    func extractPowByIterator(
        expr: Expression_<A>,
        iteratorName: String
    ): Option<A> {
        match (expr) {
            case Function(functionName, functionArgs) =>
                if (functionName != "pow" || functionArgs.size != 2) {
                    return None
                }
                match ((functionArgs[0], functionArgs[1])) {
                    case (Constant(base), Variable(name)) =>
                        if (name == iteratorName) {
                            Some(base)
                        } else {
                            None
                        }
                    case _ => None
                }
            case _ => None
        }
    }

    func extractGeometricParameters(
        term: Expression_<A>,
        iteratorName: String
    ): Option<(A, A)> {
        match (term) {
            case Function(_, _) =>
                match (this.extractPowByIterator(term, iteratorName)) {
                    case Some(base) => Some((A.one(), base))
                    case None => None
                }
            case Multiply(constantPart, terms) =>
                if (terms.size != 1) {
                    return None
                }
                for ((factorExpr, factorPower) in terms) {
                    if (!A.eq(factorPower, A.one())) {
                        return None
                    }
                    match (this.extractPowByIterator(factorExpr, iteratorName)) {
                        case Some(base) => return Some((constantPart, base))
                        case None => return None
                    }
                }
                None
            case _ => None
        }
    }

    func evaluateGeometricClosedForm(
        a: A,
        q: A,
        leftBound: A,
        rightBound: A
    ): Option<Expression_<A>> {
        let fromIntOption = this.scalarToNonNegativeInt(leftBound)
        let toIntOption = this.scalarToNonNegativeInt(rightBound)
        match ((fromIntOption, toIntOption)) {
            case (Some(fromInt), Some(toInt)) =>
                if (fromInt > toInt) {
                    return Some(this.zeroExpression())
                }
                let count = toInt - fromInt + 1
                let qPowFrom = A.powInt(q, fromInt)
                if (A.eq(q, A.one())) {
                    return Some(Constant(A.mul(a, A.fromInt(count))))
                }
                let qPowCount = A.powInt(q, count)
                let oneMinusQPowCount = A.add(
                    A.one(),
                    A.mul(A.fromInt(-1), qPowCount)
                )
                let oneMinusQ = A.add(
                    A.one(),
                    A.mul(A.fromInt(-1), q)
                )
                let numerator = A.mul(A.mul(a, qPowFrom), oneMinusQPowCount)
                Some(Constant(A.div(numerator, oneMinusQ)))
            case _ => None
        }
    }

    func evaluateConstantBounds(
        term: Expression_<A>,
        iteratorName: String,
        leftBound: A,
        rightBound: A
    ): Expression_<A> {
        match (this.extractGeometricParameters(term, iteratorName)) {
            case Some((a, q)) =>
                match (this.evaluateGeometricClosedForm(a, q, leftBound, rightBound)) {
                    case Some(closedFormValue) => closedFormValue
                    case None =>
                        this.evaluateRangeSum(
                            term,
                            iteratorName,
                            leftBound,
                            rightBound
                        )
                }
            case None =>
                this.evaluateRangeSum(
                    term,
                    iteratorName,
                    leftBound,
                    rightBound
                )
        }
    }

    public func simplifyPartialSum(args: ArrayList<Expression_<A>>): Expression_<A> {
        if (args.size != 4) {
            return Function("partial_sum", args)
        }

        let normalizedArgs = this.normalizeArgs(args)
        let term = normalizedArgs[0]
        let iteratorExpr = normalizedArgs[1]
        let fromExpr = normalizedArgs[2]
        let toExpr = normalizedArgs[3]

        match (iteratorExpr) {
            case Variable(iteratorName) =>
                match ((fromExpr, toExpr)) {
                    case (Constant(leftBound), Constant(rightBound)) =>
                        this.evaluateConstantBounds(
                            term,
                            iteratorName,
                            leftBound,
                            rightBound
                        )
                    case _ => Function("partial_sum", normalizedArgs)
                }
            case _ => Function("partial_sum", normalizedArgs)
        }
    }
}
