package symcalc
import std.collection.*
import std.sort.*

extend<A> Expression_<A> where A <: Scalar<A> & Comparable<A> {
    func usesIntegerDivision(): Bool {
        A.div(A.fromInt(3), A.fromInt(2)).compare(A.fromInt(1)) == Ordering.EQ
    }

    func mergeCoefficient(
        terms: HashMap<Expression_<A>, A>,
        term: Expression_<A>,
        coefficient: A
    ): Bool {
        match (terms.get(term)) {
            case Some(existingCoefficient) =>
                let updated = A.add(coefficient, existingCoefficient)
                if (A.isZero(updated)) {
                    terms.remove(term)
                } else {
                    terms.add(term, updated)
                }
                true
            case None =>
                if (!A.isZero(coefficient)) {
                    terms.add(term, coefficient)
                }
                false
        }
    }

    func sameTermsMap(
        left: HashMap<Expression_<A>, A>,
        right: HashMap<Expression_<A>, A>
    ): Bool {
        if (left.size != right.size) {
            return false
        }
        for ((key, leftValue) in left) {
            match (right.get(key)) {
                case Some(rightValue) =>
                    if (leftValue.compare(rightValue) != Ordering.EQ) {
                        return false
                    }
                case None => return false
            }
        }
        true
    }

    func powScalar(base: A, exp: A): A {
        if (exp.compare(A.zero()) != Ordering.GT) {
            return A.one()
        }

        if (!this.usesIntegerDivision()) {
            // Preserve previous semantics for non-integer division scalars (e.g. Float64).
            var linearAns: A = A.one()
            var linearExp: A = exp
            while (linearExp.compare(A.zero()) == Ordering.GT) {
                linearAns = A.mul(linearAns, base)
                linearExp = A.add(linearExp, A.fromInt(-1))
            }
            return linearAns
        }

        var ans: A = A.one()
        var curBase: A = base
        var e: A = exp
        let two = A.fromInt(2)
        while (e.compare(A.zero()) == Ordering.GT) {
            let half = A.div(e, two)
            let doubledHalf = A.mul(half, two)
            let isOdd = doubledHalf.compare(e) != Ordering.EQ
            if (isOdd) {
                ans = A.mul(ans, curBase)
            }
            curBase = A.mul(curBase, curBase)
            e = half
        }
        ans
    }

    func multiplyNorm(
        constantPart: A,
        terms_: HashMap<Expression_<A>, A>
    ): (Expression_<A>, Bool) {
        var expr = Multiply(constantPart, terms_)
        var normalizedConstantPart: A = constantPart
        var normalizedTerms: HashMap<Expression_<A>, A> = HashMap<Expression_<A>, A>()
        var changed = false
        if(terms_.isEmpty()){
            expr = Add(normalizedConstantPart, HashMap<Expression_<A>, A>())
            return (expr, true)
        }
        for((term_, coefficient) in terms_){
            match (term_) {
                case Constant(termConstant) => 
                    if(coefficient.compare(A.zero()) == Ordering.LT){
                        if (this.mergeCoefficient(normalizedTerms, term_, coefficient)) {
                            changed = true
                        }
                        continue
                    }
                    normalizedConstantPart =
                        A.mul(normalizedConstantPart, powScalar(termConstant, coefficient))
                    changed = true
                case Function(_,_)  => 
                    if (this.mergeCoefficient(normalizedTerms, term_, coefficient)) {
                        changed = true
                    }
                case Variable(_) => 
                    if (this.mergeCoefficient(normalizedTerms, term_, coefficient)) {
                        changed = true
                    }
                case Add(nestedConstantPart,nestedTerms) => 
                    if(coefficient.compare(A.zero()) == Ordering.LT){
                        if (this.mergeCoefficient(normalizedTerms, term_, coefficient)) {
                            changed = true
                        }
                        continue
                    }
                    var newExpr: Expression_<A> = Add(A.zero(), HashMap<Expression_<A>, A>())
                    let updatedCoeff = A.add(coefficient, A.fromInt(-1))
                    if (A.isZero(updatedCoeff)){
                        terms_.remove(term_)
                    }else{
                        terms_.add(term_, updatedCoeff)
                    }
                    expr = Multiply(constantPart, terms_)
                    
                    newExpr = newExpr + (Constant(nestedConstantPart) * expr)
                    
                    for((nestedTerm, nestedCoefficient) in nestedTerms){
                        newExpr = newExpr + (nestedTerm * expr) * Constant(nestedCoefficient)
                    }
                    expr = newExpr
                    return (expr, true)
                case Multiply(multConstantPart,multTerms) => 
                    normalizedConstantPart = A.mul(normalizedConstantPart, multConstantPart)
                    changed = true
                    for((term_, val_) in multTerms){
                        match (normalizedTerms.get(term_)) {
                            case Some(existingCoefficient) =>
                                let updated = A.add(A.add(coefficient, existingCoefficient), val_)
                                if (A.isZero(updated)) {
                                    normalizedTerms.remove(term_)
                                } else {
                                    normalizedTerms.add(term_, updated)
                                }
                                changed = true
                            case None =>
                                normalizedTerms.add(term_, val_)
                        }
                    }
                    
            }
        }
        expr = Multiply(normalizedConstantPart,normalizedTerms)
        (expr, changed)
    }
    
    
    func toSemiNormalForm(): Expression_<A> {
        var expr: Expression_<A> = this
        var changedInPass = true
        while(changedInPass){
            changedInPass = false
            match (expr) {
                case Constant(constantValue) => expr = Constant(constantValue)
                case Variable(variableName) => expr = Variable(variableName)
                case Add(constantPart,terms) => 
                    var normalizedConstantPart: A = constantPart
                    var normalizedTerms: HashMap<Expression_<A>, A> = HashMap<Expression_<A>, A>()
                    var addChanged = false
                    for((term, coefficient) in terms){
                        match (term) {
                            case Constant(termConstant) =>
                                normalizedConstantPart = A.add(
                                    normalizedConstantPart,
                                    A.mul(termConstant, coefficient)
                                )
                                addChanged = true
                            case Variable(_) =>
                                if (this.mergeCoefficient(normalizedTerms, term, coefficient)) {
                                    addChanged = true
                                }
                            case Add(nestedConstantPart,nestedTerms) => 
                                var normalizedAdd: Expression_<A> =
                                    Add(nestedConstantPart, nestedTerms).toNormalForm()
                                match (normalizedAdd) {
                                    case Add(addConstantPart,addTerms) => 
                                        addChanged = true
                                        normalizedConstantPart = A.add(
                                            normalizedConstantPart,
                                            A.mul(addConstantPart, coefficient)
                                        )
                                        for((addTerm,addCoefficient) in addTerms){
                                            if (this.mergeCoefficient(
                                                normalizedTerms,
                                                addTerm,
                                                A.mul(addCoefficient, coefficient)
                                            )) {
                                                addChanged = true
                                            }
                                        }
                                    case _ => 0
                                }
                                
                            case Multiply(multConstantPart,multTerms) => 
                                var normalizedMult: Expression_<A> =
                                    Multiply(multConstantPart, multTerms).toNormalForm()
                                match (normalizedMult) {
                                    case Constant(value) =>
                                        addChanged = true
                                        normalizedConstantPart = A.add(
                                            normalizedConstantPart,
                                            A.mul(value, coefficient)
                                        )
                                    case Multiply(normConst, normTerms) =>
                                        if (normTerms.isEmpty()) {
                                            addChanged = true
                                            normalizedConstantPart = A.add(
                                                normalizedConstantPart,
                                                A.mul(normConst, coefficient)
                                            )
                                        } else {
                                            let canonicalTerm = Multiply(A.one(), normTerms)
                                            let delta = A.mul(normConst, coefficient)
                                            if (
                                                !(
                                                    A.eq(multConstantPart, A.one()) &&
                                                    A.eq(normConst, A.one()) &&
                                                    this.sameTermsMap(multTerms, normTerms) &&
                                                    coefficient.compare(delta) == Ordering.EQ
                                                )
                                            ) {
                                                addChanged = true
                                            }
                                            if (this.mergeCoefficient(normalizedTerms, canonicalTerm, delta)) {
                                                addChanged = true
                                            }
                                        }
                                    case _ =>
                                        addChanged = true
                                        if (this.mergeCoefficient(normalizedTerms, normalizedMult, coefficient)) {
                                            addChanged = true
                                        }
                                }
                            case a =>
                                if (this.mergeCoefficient(normalizedTerms, term, coefficient)) {
                                    addChanged = true
                                }
                        }

                    }
                    expr = Add(normalizedConstantPart,normalizedTerms)
                    changedInPass = addChanged
                    
                //it can be better
                case Multiply(constantPart,terms_) => 
                    let (normalizedExpr, multChanged) = multiplyNorm(constantPart,terms_.clone())
                    expr = normalizedExpr
                    changedInPass = multChanged
                case a =>
                    expr = a
            }
        }
        expr
        
    }

    public func toNormalForm(){
        this.toSemiNormalForm()
    }
}
