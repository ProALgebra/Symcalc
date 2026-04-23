package symcalc
import std.collection.*

extend<A> Expression_<A>
where A <: Scalar<A> & Comparable<A> & Hashable & ToString & Equatable<A> {
    public func derivative(elemet: Expression_<A>): Expression_<A> {
        this.derivativeWithRules(FunctionRules<A>(), elemet)
    }

    public func derivativeWithRules(
        functionRules: FunctionRules<A>,
        elemet: Expression_<A>
    ): Expression_<A> {
        var derivativeOfExpr = this
        let normalElement = elemet.toNormalForm()
        derivativeOfExpr = derivativeOfExpr.toNormalForm()
        if (normalElement == derivativeOfExpr) {
            return Add(A.one(), HashMap<Expression_<A>, A>())
        }
        match (derivativeOfExpr) {
            case Constant(_) => return Add(A.zero(), HashMap<Expression_<A>, A>())
            case Variable(_) =>
                if (normalElement == derivativeOfExpr) {
                    return Add(A.one(), HashMap<Expression_<A>, A>())
                } else {
                    return Add(A.zero(), HashMap<Expression_<A>, A>())
                }
            case Function(functionName, functionArgs) =>
                return functionRules.derivativeFunction(functionName, functionArgs, normalElement)
            case Add(_, terms) =>
                var result = Add(A.zero(), HashMap<Expression_<A>, A>())
                for ((t, v) in terms) {
                    if (A.isZero(v)) {
                        continue
                    }
                    let dTerm = t.derivativeWithRules(functionRules, normalElement).toNormalForm()
                    let contribution = if (A.eq(v, A.one())) {
                        dTerm
                    } else {
                        (Constant(v) * dTerm).toNormalForm()
                    }
                    result = (result + contribution).toNormalForm()
                }
                return result.toNormalForm()
            case Multiply(constant, terms) =>
                var result = Multiply(A.one(), HashMap<Expression_<A>, A>())
                var copyTerms = terms.clone()
                match (copyTerms.get(normalElement)) {
                    case Some(existingCoefficient) =>
                        let updated = A.add(existingCoefficient, A.fromInt(-1))
                        if (A.isZero(updated)) {
                            copyTerms.remove(normalElement)
                        } else {
                            copyTerms.add(normalElement, updated)
                        }
                        result = result * Multiply(
                            A.mul(constant, existingCoefficient),
                            copyTerms
                        )
                    case None => 0
                }
                return result.toNormalForm()
            case a => a
        }
    }
}
