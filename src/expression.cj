package symcalc
import std.console.*
import std.collection.*
import std.sort.*

enum Expression_<A> where A <: Scalar<A> & Comparable<A> & Hashable & ToString & Equatable<A>{
    | Constant(A)
    | Variable(String)
    | Multiply(A, HashMap<Expression_<A>,A>)
    | Add(A, HashMap<Expression_<A>,A>)
    | Function(String,ArrayList<Expression_<A>>)

    public operator func +(that: Expression_<A>) : Expression_<A> {
        let left = this
        let right = that

        var constantPart = A.zero()
        var terms = HashMap<Expression_<A>, A>()

        match (left) {
            case Add(leftConstant, leftTerms) =>
                constantPart = A.add(constantPart, leftConstant)
                for ((term, coefficient) in leftTerms) {
                    match (terms.get(term)) {
                        case Some(existingCoefficient) =>
                            let updated = A.add(existingCoefficient, coefficient)
                            if (A.isZero(updated)) {
                                terms.remove(term)
                            } else {
                                terms.add(term, updated)
                            }
                        case None =>
                            if (!A.isZero(coefficient)) {
                                terms.add(term, coefficient)
                            }
                    }
                }
            case _ =>
                match (terms.get(left)) {
                    case Some(existingCoefficient) =>
                        let updated = A.add(existingCoefficient, A.one())
                        if (A.isZero(updated)) {
                            terms.remove(left)
                        } else {
                            terms.add(left, updated)
                        }
                    case None => terms.add(left, A.one())
                }
        }

        match (right) {
            case Add(rightConstant, rightTerms) =>
                constantPart = A.add(constantPart, rightConstant)
                for ((term, coefficient) in rightTerms) {
                    match (terms.get(term)) {
                        case Some(existingCoefficient) =>
                            let updated = A.add(existingCoefficient, coefficient)
                            if (A.isZero(updated)) {
                                terms.remove(term)
                            } else {
                                terms.add(term, updated)
                            }
                        case None =>
                            if (!A.isZero(coefficient)) {
                                terms.add(term, coefficient)
                            }
                    }
                }
            case _ =>
                match (terms.get(right)) {
                    case Some(existingCoefficient) =>
                        let updated = A.add(existingCoefficient, A.one())
                        if (A.isZero(updated)) {
                            terms.remove(right)
                        } else {
                            terms.add(right, updated)
                        }
                    case None => terms.add(right, A.one())
                }
        }

        Add(constantPart, terms).toNormalForm()
    }
    public operator func *(that: Expression_<A>) : Expression_<A> {
        let left = this
        let right = that

        var constantPart = A.one()
        var terms = HashMap<Expression_<A>, A>()

        match (left) {
            case Multiply(leftConstant, leftTerms) =>
                constantPart = A.mul(constantPart, leftConstant)
                for ((term, coefficient) in leftTerms) {
                    match (terms.get(term)) {
                        case Some(existingCoefficient) =>
                            let updated = A.add(existingCoefficient, coefficient)
                            if (A.isZero(updated)) {
                                terms.remove(term)
                            } else {
                                terms.add(term, updated)
                            }
                        case None =>
                            if (!A.isZero(coefficient)) {
                                terms.add(term, coefficient)
                            }
                    }
                }
            case _ =>
                match (terms.get(left)) {
                    case Some(existingCoefficient) =>
                        let updated = A.add(existingCoefficient, A.one())
                        if (A.isZero(updated)) {
                            terms.remove(left)
                        } else {
                            terms.add(left, updated)
                        }
                    case None => terms.add(left, A.one())
                }
        }

        match (right) {
            case Multiply(rightConstant, rightTerms) =>
                constantPart = A.mul(constantPart, rightConstant)
                for ((term, coefficient) in rightTerms) {
                    match (terms.get(term)) {
                        case Some(existingCoefficient) =>
                            let updated = A.add(existingCoefficient, coefficient)
                            if (A.isZero(updated)) {
                                terms.remove(term)
                            } else {
                                terms.add(term, updated)
                            }
                        case None =>
                            if (!A.isZero(coefficient)) {
                                terms.add(term, coefficient)
                            }
                    }
                }
            case _ =>
                match (terms.get(right)) {
                    case Some(existingCoefficient) =>
                        let updated = A.add(existingCoefficient, A.one())
                        if (A.isZero(updated)) {
                            terms.remove(right)
                        } else {
                            terms.add(right, updated)
                        }
                    case None => terms.add(right, A.one())
                }
        }

        Multiply(constantPart, terms).toNormalForm()
    }


}

extend<A> Expression_<A> where A <: Scalar<A> & Comparable<A> & Hashable & ToString & Equatable<A> {
    public func substituteVariable(
        variableName: String,
        replacement: Expression_<A>
    ): Expression_<A> {
        match (this) {
            case Constant(_) => this
            case Variable(name) =>
                if (name == variableName) {
                    replacement
                } else {
                    this
                }
            case Add(constantPart, terms) =>
                var substitutedTerms = HashMap<Expression_<A>, A>()
                for ((term, coefficient) in terms) {
                    let substitutedTerm = term.substituteVariable(variableName, replacement)
                    match (substitutedTerms.get(substitutedTerm)) {
                        case Some(existingCoefficient) =>
                            let updated = A.add(existingCoefficient, coefficient)
                            if (A.isZero(updated)) {
                                substitutedTerms.remove(substitutedTerm)
                            } else {
                                substitutedTerms.add(substitutedTerm, updated)
                            }
                        case None => substitutedTerms.add(substitutedTerm, coefficient)
                    }
                }
                Add(constantPart, substitutedTerms).toNormalForm()
            case Multiply(constantPart, terms) =>
                var substitutedTerms = HashMap<Expression_<A>, A>()
                for ((term, coefficient) in terms) {
                    let substitutedTerm = term.substituteVariable(variableName, replacement)
                    match (substitutedTerms.get(substitutedTerm)) {
                        case Some(existingCoefficient) =>
                            let updated = A.add(existingCoefficient, coefficient)
                            if (A.isZero(updated)) {
                                substitutedTerms.remove(substitutedTerm)
                            } else {
                                substitutedTerms.add(substitutedTerm, updated)
                            }
                        case None => substitutedTerms.add(substitutedTerm, coefficient)
                    }
                }
                Multiply(constantPart, substitutedTerms).toNormalForm()
            case Function(functionName, args) =>
                var substitutedArgs = ArrayList<Expression_<A>>([])
                for (arg in args) {
                    substitutedArgs.add(arg.substituteVariable(variableName, replacement))
                }
                Function(functionName, substitutedArgs).toNormalForm()
        }
    }

    public func substituteVariable(
        variable: Expression_<A>,
        replacement: Expression_<A>
    ): Expression_<A> {
        let normalizedVariable = variable.toNormalForm()
        match (normalizedVariable) {
            case Variable(name) => this.substituteVariable(name, replacement)
            case _ => this
        }
    }
}

extend<A> Expression_<A> <: Equatable<Expression_<A>> where A <: Scalar<A> & Equatable<A> {
    public operator func ==(other: Expression_<A>): Bool {
        this.hashCode() == other.hashCode()
    }

    public operator func !=(other: Expression_<A>): Bool {
        !(this == other)
    }
}
