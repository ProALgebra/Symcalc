package symcalc
import std.collection.*
import std.sort.*

extend<A> Expression_<A> where A <: Scalar<A> & Comparable<A> {
    func powScalar(base: A, exp: A): A {
        var ans: A = A.one()
        var e: A = exp
        while (e.compare(A.zero()) == Ordering.GT) {
            ans = A.mul(ans, base)
            e = A.add(e, A.fromInt(-1))
        }
        ans
    }

    func multiplyNorm(constantPart: A, terms_: HashMap<Expression_<A>, A>): Expression_<A> {
        var expr = Multiply(constantPart, terms_)
        var normalizedConstantPart: A = constantPart
        var normalizedTerms: HashMap<Expression_<A>, A> = HashMap<Expression_<A>, A>()
        if(terms_.isEmpty()){
            expr = Add(normalizedConstantPart, HashMap<Expression_<A>, A>())
            return expr
        }
        for((term_, coefficient) in terms_){
            match (term_) {
                case Constant(termConstant) => 
                    if(coefficient.compare(A.zero()) == Ordering.LT){
                        match (normalizedTerms.get(term_)) {
                            case Some(existingCoefficient) => 
                                let updated = A.add(coefficient, existingCoefficient)
                                if (A.isZero(updated)){
                                    normalizedTerms.remove(term_)
                                }else{
                                    normalizedTerms.add(term_, updated)
                                }
                            case None => normalizedTerms.add(term_,coefficient)
                        }
                        continue
                    }
                    normalizedConstantPart =
                        A.mul(normalizedConstantPart, powScalar(termConstant, coefficient))
                case Function(_,_)  => 
                    match (normalizedTerms.get(term_)) {
                        case Some(existingCoefficient) => 
                            let updated = A.add(coefficient, existingCoefficient)
                            if (A.isZero(updated)){
                                normalizedTerms.remove(term_)
                            }else{
                                normalizedTerms.add(term_, updated)
                            }
                        case None => normalizedTerms.add(term_,coefficient)
                    }
                case Variable(_) => 
                    match (normalizedTerms.get(term_)) {
                        case Some(existingCoefficient) => 
                            let updated = A.add(coefficient, existingCoefficient)
                            if (A.isZero(updated)){
                                normalizedTerms.remove(term_)
                            }else{
                                normalizedTerms.add(term_, updated)
                            }
                        case None => normalizedTerms.add(term_,coefficient)
                    }
                case Add(nestedConstantPart,nestedTerms) => 
                    if(coefficient.compare(A.zero()) == Ordering.LT){
                        match (normalizedTerms.get(term_)) {
                            case Some(existingCoefficient) => 
                                let updated = A.add(coefficient, existingCoefficient)
                                if (A.isZero(updated)){
                                    normalizedTerms.remove(term_)
                                }else{
                                    normalizedTerms.add(term_, updated)
                                }
                            case None => normalizedTerms.add(term_,coefficient)
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
                    return expr
                case Multiply(multConstantPart,multTerms) => 
                    normalizedConstantPart = A.mul(normalizedConstantPart, multConstantPart)
                    for((term_, val_) in multTerms){
                        match (normalizedTerms.get(term_)) {
                        case Some(existingCoefficient) => 
                            let updated = A.add(A.add(coefficient, existingCoefficient), val_)
                            if (A.isZero(updated)){
                                normalizedTerms.remove(term_)
                            }else{
                                normalizedTerms.add(term_, updated)
                            }
                        case None => normalizedTerms.add(term_,val_)
                    }
                    }
                    
            }
        }
        expr = Multiply(normalizedConstantPart,normalizedTerms)
        expr
    }
    
    
    func toSemiNormalForm(): Expression_<A> {
        var expr: Expression_<A> = this
        var old: Expression_<A> = this
        var state: Bool = true;
        while(state){
            match (expr) {
                case Constant(constantValue) => expr = Constant(constantValue)
                case Variable(variableName) => expr = Variable(variableName)
                case Add(constantPart,terms) => 
                    var normalizedConstantPart: A = constantPart
                    var normalizedTerms: HashMap<Expression_<A>, A> = HashMap<Expression_<A>, A>()
                    for((term, coefficient) in terms){
                        match (term) {
                            case Constant(termConstant) =>
                                normalizedConstantPart = A.add(
                                    normalizedConstantPart,
                                    A.mul(termConstant, coefficient)
                                )
                            case Variable(_) => match (normalizedTerms.get(term)) {
                                case Some(existingCoefficient) => 
                                    let updated = A.add(coefficient, existingCoefficient)
                                    if (A.isZero(updated)){
                                        normalizedTerms.remove(term)
                                    }else{
                                        normalizedTerms.add(term, updated)
                                    }
                                case None => normalizedTerms.add(term,coefficient)
                            }
                            case Add(nestedConstantPart,nestedTerms) => 
                                var normalizedAdd: Expression_<A> =
                                    Add(nestedConstantPart, nestedTerms).toNormalForm()
                                match (normalizedAdd) {
                                    case Add(addConstantPart,addTerms) => 
                                        normalizedConstantPart = A.add(
                                            normalizedConstantPart,
                                            A.mul(addConstantPart, coefficient)
                                        )
                                        for((addTerm,addCoefficient) in addTerms){
                                            match (normalizedTerms.get(addTerm)) {
                                                case Some(existingCoefficient) => 
                                                    let updated = A.add(
                                                        A.mul(addCoefficient, coefficient),
                                                        existingCoefficient
                                                    )
                                                    if (A.isZero(updated)){
                                                        normalizedTerms.remove(addTerm)
                                                    }else{
                                                        normalizedTerms.add(addTerm, updated)
                                                    }
                                                case None => normalizedTerms.add(
                                                    addTerm,
                                                    A.mul(addCoefficient, coefficient)
                                                )
                                            }
                                        }
                                    case _ => 0
                                }
                                
                            case Multiply(multConstantPart,multTerms) => 
                                var normalizedMult: Expression_<A> =
                                    Multiply(multConstantPart, multTerms).toNormalForm()

                                if(multTerms.isEmpty()){
                                    normalizedConstantPart = A.add(
                                        normalizedConstantPart,
                                        multConstantPart
                                    )
                                    continue
                                }
                                if(multTerms.size == 1){
                                    for((t,v) in multTerms){
                                        if(A.eq(v, A.one())){
                                            match(t){
                                                case Variable(_) =>
                                                    normalizedMult = Add(
                                                        A.zero(),
                                                        HashMap<Expression_<A>, A>((t, multConstantPart))
                                                    )
                                                case a => a
                                            }
                                        }
                                    }
                                }
                                match (normalizedTerms.get(normalizedMult)) {
                                    case Some(existingCoefficient) => 
                                        let updated = A.add(coefficient, existingCoefficient)
                                        if(A.isZero(updated)){
                                            normalizedTerms.remove(normalizedMult)
                                        }
                                        else{
                                            normalizedTerms.add(normalizedMult, updated)
                                        }
                                    case None => normalizedTerms.add(normalizedMult,coefficient)
                                }
                            case a =>
                                match (normalizedTerms.get(term)) {
                                    case Some(existingCoefficient) => 
                                        let updated = A.add(coefficient, existingCoefficient)
                                        if (A.isZero(updated)){
                                            normalizedTerms.remove(term)
                                        }else{
                                            normalizedTerms.add(term, updated)
                                        }
                                    case None => normalizedTerms.add(term,coefficient)
                            }
                        }

                    }
                    expr = Add(normalizedConstantPart,normalizedTerms)
                    
                //it can be better
                case Multiply(constantPart,terms_) => 
                    expr = multiplyNorm(constantPart,terms_.clone())
                case a =>
                    a
            }
            if(expr.hashCode() == old.hashCode()){
                state = false
            }else{
                old = expr
            }
        }
        expr
        
    }

    public func toNormalForm(){
        this.toSemiNormalForm()
    }
}
