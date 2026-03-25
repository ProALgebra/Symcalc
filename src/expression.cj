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
        let x: Expression_<A> = this
        if(x.hashCode() == that.hashCode()){
            Add(A.zero(), HashMap<Expression_<A>,A>((this, A.fromInt(2)))).toNormalForm()
        }else{
            Add(
                A.zero(),
                HashMap<Expression_<A>,A>((this, A.one()), (that, A.one()))
            ).toNormalForm()
        }
    }
    public operator func *(that: Expression_<A>) : Expression_<A> {
        let x: Expression_<A> = this
        if(x.hashCode() == that.hashCode()){
            Multiply(A.one(), HashMap<Expression_<A>,A>((this, A.fromInt(2)))).toNormalForm()
        }else{
            Multiply(
                A.one(),
                HashMap<Expression_<A>,A>((this, A.one()), (that, A.one()))
            ).toNormalForm()
        }
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
