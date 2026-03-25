package symcalc
import std.collection.*
import std.sort.*

class GeometricRules<A> where A <: Scalar<A> & Comparable<A> & Hashable & ToString & Equatable<A> {
    func normalizeArgs(args: ArrayList<Expression_<A>>): ArrayList<Expression_<A>> {
        var normalized = ArrayList<Expression_<A>>([])
        for (arg in args) {
            normalized.add(arg.toNormalForm())
        }
        normalized
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

    public func simplifyPow(args: ArrayList<Expression_<A>>): Expression_<A> {
        if (args.size != 2) {
            return Function("pow", args)
        }
        let normalizedArgs = this.normalizeArgs(args)
        let baseExpr = normalizedArgs[0]
        let exponentExpr = normalizedArgs[1]
        match ((baseExpr, exponentExpr)) {
            case (Constant(base), Constant(exponent)) =>
                match (this.scalarToNonNegativeInt(exponent)) {
                    case Some(exponentInt) =>
                        Constant(A.powInt(base, exponentInt))
                    case None => Function("pow", normalizedArgs)
                }
            case _ => Function("pow", normalizedArgs)
        }
    }

    public func simplifyGeomSum(args: ArrayList<Expression_<A>>): Expression_<A> {
        if (args.size != 4) {
            return Function("geom_sum", args)
        }
        let normalizedArgs = this.normalizeArgs(args)
        let aExpr = normalizedArgs[0]
        let qExpr = normalizedArgs[1]
        let fromExpr = normalizedArgs[2]
        let toExpr = normalizedArgs[3]

        match ((aExpr, qExpr, fromExpr, toExpr)) {
            case (
                Constant(a),
                Constant(q),
                Constant(fromBound),
                Constant(toBound)
            ) =>
                match ((
                    this.scalarToNonNegativeInt(fromBound),
                    this.scalarToNonNegativeInt(toBound)
                )) {
                    case (Some(fromInt), Some(toInt)) =>
                        if (fromInt > toInt) {
                            return Add(A.zero(), HashMap<Expression_<A>, A>())
                        }
                        let count = toInt - fromInt + 1
                        let qPowFrom = A.powInt(q, fromInt)
                        if (A.eq(q, A.one())) {
                            return Constant(A.mul(a, A.fromInt(count)))
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
                        Constant(A.div(numerator, oneMinusQ))
                    case _ => Function("geom_sum", normalizedArgs)
                }
            case _ => Function("geom_sum", normalizedArgs)
        }
    }
}
