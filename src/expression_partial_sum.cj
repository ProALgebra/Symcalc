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

    func evaluateConstantExpression(expr: Expression_<A>): Option<A> {
        match (expr.toNormalForm()) {
            case Constant(value) => Some(value)
            case Variable(_) => None
            case Add(constantPart, terms) =>
                var total = constantPart
                for ((term, coefficient) in terms) {
                    match (this.evaluateConstantExpression(term)) {
                        case Some(termValue) =>
                            total = A.add(total, A.mul(coefficient, termValue))
                        case None => return None
                    }
                }
                Some(total)
            case Multiply(constantPart, terms) =>
                var total = constantPart
                for ((term, power) in terms) {
                    match (this.evaluateConstantExpression(term)) {
                        case Some(termValue) =>
                            match (this.scalarToNonNegativeInt(power)) {
                                case Some(powerInt) =>
                                    total = A.mul(total, A.powInt(termValue, powerInt))
                                case None => return None
                            }
                        case None => return None
                    }
                }
                Some(total)
            case Function(functionName, functionArgs) =>
                if (functionName != "pow" || functionArgs.size != 2) {
                    return None
                }
                match ((
                    this.evaluateConstantExpression(functionArgs[0]),
                    this.evaluateConstantExpression(functionArgs[1])
                )) {
                    case (Some(baseValue), Some(exponentValue)) =>
                        match (this.scalarToNonNegativeInt(exponentValue)) {
                            case Some(exponentInt) => Some(A.powInt(baseValue, exponentInt))
                            case None => None
                        }
                    case _ => None
                }
        }
    }

    func evaluateTermAsConstant(
        term: Expression_<A>,
        iteratorName: String,
        at: A
    ): Option<A> {
        let substituted = term.substituteVariable(iteratorName, Constant(at))
        this.evaluateConstantExpression(substituted)
    }

    func scalarSub(left: A, right: A): A {
        A.add(left, A.mul(A.fromInt(-1), right))
    }

    func expressionUsesVariable(
        expr: Expression_<A>,
        iteratorName: String
    ): Bool {
        match (expr.toNormalForm()) {
            case Constant(_) => false
            case Variable(name) => name == iteratorName
            case Add(_, terms) =>
                for ((term, _) in terms) {
                    if (this.expressionUsesVariable(term, iteratorName)) {
                        return true
                    }
                }
                false
            case Multiply(_, terms) =>
                for ((term, _) in terms) {
                    if (this.expressionUsesVariable(term, iteratorName)) {
                        return true
                    }
                }
                false
            case Function(_, args) =>
                for (arg in args) {
                    if (this.expressionUsesVariable(arg, iteratorName)) {
                        return true
                    }
                }
                false
        }
    }

    func extractAffineByIterator(
        term: Expression_<A>,
        iteratorName: String
    ): Option<(A, A)> {
        let normalizedTerm = term.toNormalForm()
        match (normalizedTerm) {
            case Variable(name) =>
                if (name == iteratorName) {
                    Some((A.one(), A.zero()))
                } else {
                    None
                }
            case Add(constantPart, terms) =>
                var linear = A.zero()
                var bias = constantPart
                for ((singleTerm, coefficient) in terms) {
                    match (singleTerm) {
                        case Variable(name) =>
                            if (name == iteratorName) {
                                linear = A.add(linear, coefficient)
                            } else {
                                if (this.expressionUsesVariable(singleTerm, iteratorName)) {
                                    return None
                                }
                                match (this.evaluateConstantExpression(singleTerm)) {
                                    case Some(value) =>
                                        bias = A.add(bias, A.mul(coefficient, value))
                                    case None => return None
                                }
                            }
                        case _ =>
                            if (this.expressionUsesVariable(singleTerm, iteratorName)) {
                                return None
                            }
                            match (this.evaluateConstantExpression(singleTerm)) {
                                case Some(value) =>
                                    bias = A.add(bias, A.mul(coefficient, value))
                                case None => return None
                            }
                    }
                }
                Some((linear, bias))
            case _ => None
        }
    }

    func evaluateAffineClosedForm(
        linear: A,
        bias: A,
        leftBound: A,
        rightBound: A
    ): Expression_<A> {
        if (leftBound.compare(rightBound) == Ordering.GT) {
            return this.zeroExpression()
        }

        let n = A.add(this.scalarSub(rightBound, leftBound), A.one())
        let sumIndices = A.div(A.mul(n, A.add(leftBound, rightBound)), A.fromInt(2))
        let sumValue = A.add(A.mul(linear, sumIndices), A.mul(bias, n))
        Constant(sumValue).toNormalForm()
    }

    func usesIntegerDivision(): Bool {
        A.div(A.fromInt(3), A.fromInt(2)).compare(A.fromInt(1)) == Ordering.EQ
    }

    func computeTermsCount(leftBound: A, rightBound: A): Option<Int> {
        match ((
            this.scalarToNonNegativeInt(leftBound),
            this.scalarToNonNegativeInt(rightBound)
        )) {
            case (Some(leftInt), Some(rightInt)) =>
                if (leftInt > rightInt) {
                    Some(0)
                } else {
                    Some(rightInt - leftInt + 1)
                }
            case _ => None
        }
    }

    func collectSequenceValues(
        term: Expression_<A>,
        iteratorName: String,
        leftBound: A,
        count: Int
    ): Option<ArrayList<A>> {
        var values = ArrayList<A>([])
        var current = leftBound
        var idx = 0
        while (idx < count) {
            match (this.evaluateTermAsConstant(term, iteratorName, current)) {
                case Some(value) => values.add(value)
                case None => return None
            }
            current = A.add(current, A.one())
            idx += 1
        }
        Some(values)
    }

    func determinant3x3(
        a11: A, a12: A, a13: A,
        a21: A, a22: A, a23: A,
        a31: A, a32: A, a33: A
    ): A {
        let t1 = A.mul(a11, this.scalarSub(A.mul(a22, a33), A.mul(a23, a32)))
        let t2 = A.mul(a12, this.scalarSub(A.mul(a21, a33), A.mul(a23, a31)))
        let t3 = A.mul(a13, this.scalarSub(A.mul(a21, a32), A.mul(a22, a31)))
        A.add(this.scalarSub(t1, t2), t3)
    }

    func tryFindLinearRecurrenceCoefficients(
        values: ArrayList<A>,
        order: Int
    ): Option<ArrayList<A>> {
        if (order == 1) {
            if (values.size < 2 || A.isZero(values[0])) {
                return None
            }
            let c0 = A.div(values[1], values[0])
            var coeffs = ArrayList<A>([])
            coeffs.add(c0)
            var idx = 0
            while (idx + 1 < values.size) {
                let predicted = A.mul(c0, values[idx])
                if (!A.eq(predicted, values[idx + 1])) {
                    return None
                }
                idx += 1
            }
            return Some(coeffs)
        }

        if (order == 2) {
            if (values.size < 4) {
                return None
            }
            let a0 = values[0]
            let a1 = values[1]
            let a2 = values[2]
            let a3 = values[3]
            let det = this.scalarSub(A.mul(a0, a2), A.mul(a1, a1))
            if (A.isZero(det)) {
                return None
            }
            let c0 = A.div(
                this.scalarSub(A.mul(a2, a2), A.mul(a1, a3)),
                det
            )
            let c1 = A.div(
                this.scalarSub(A.mul(a0, a3), A.mul(a1, a2)),
                det
            )
            var coeffs = ArrayList<A>([])
            coeffs.add(c0)
            coeffs.add(c1)

            var idx = 0
            while (idx + 2 < values.size) {
                let predicted = A.add(
                    A.mul(c0, values[idx]),
                    A.mul(c1, values[idx + 1])
                )
                if (!A.eq(predicted, values[idx + 2])) {
                    return None
                }
                idx += 1
            }
            return Some(coeffs)
        }

        if (order == 3) {
            if (values.size < 6) {
                return None
            }
            let a0 = values[0]
            let a1 = values[1]
            let a2 = values[2]
            let a3 = values[3]
            let a4 = values[4]
            let a5 = values[5]

            let det = this.determinant3x3(
                a0, a1, a2,
                a1, a2, a3,
                a2, a3, a4
            )
            if (A.isZero(det)) {
                return None
            }

            let det0 = this.determinant3x3(
                a3, a1, a2,
                a4, a2, a3,
                a5, a3, a4
            )
            let det1 = this.determinant3x3(
                a0, a3, a2,
                a1, a4, a3,
                a2, a5, a4
            )
            let det2 = this.determinant3x3(
                a0, a1, a3,
                a1, a2, a4,
                a2, a3, a5
            )

            let c0 = A.div(det0, det)
            let c1 = A.div(det1, det)
            let c2 = A.div(det2, det)

            var coeffs = ArrayList<A>([])
            coeffs.add(c0)
            coeffs.add(c1)
            coeffs.add(c2)

            var idx = 0
            while (idx + 3 < values.size) {
                let predicted = A.add(
                    A.add(
                        A.mul(c0, values[idx]),
                        A.mul(c1, values[idx + 1])
                    ),
                    A.mul(c2, values[idx + 2])
                )
                if (!A.eq(predicted, values[idx + 3])) {
                    return None
                }
                idx += 1
            }
            return Some(coeffs)
        }

        if (values.size < order * 2) {
            return None
        }
        None
    }

    func evaluateSumByRecurrence(
        coeffs: ArrayList<A>,
        values: ArrayList<A>,
        totalCount: Int,
        order: Int
    ): A {
        if (totalCount <= 0) {
            return A.zero()
        }

        var sum = A.zero()
        var seedCount = if (totalCount < order) {
            totalCount
        } else {
            order
        }

        var idx = 0
        while (idx < seedCount) {
            sum = A.add(sum, values[idx])
            idx += 1
        }

        if (totalCount <= order) {
            return sum
        }
        if (order == 1) {
            let c0 = coeffs[0]
            var prev0 = values[0]
            var generated = 1
            while (generated < totalCount) {
                let nextValue = A.mul(c0, prev0)
                sum = A.add(sum, nextValue)
                prev0 = nextValue
                generated += 1
            }
            return sum
        }

        if (order == 2) {
            let c0 = coeffs[0]
            let c1 = coeffs[1]
            var prev0 = values[0]
            var prev1 = values[1]
            var generated = 2
            while (generated < totalCount) {
                let nextValue = A.add(A.mul(c0, prev0), A.mul(c1, prev1))
                sum = A.add(sum, nextValue)
                prev0 = prev1
                prev1 = nextValue
                generated += 1
            }
            return sum
        }

        if (order == 3) {
            let c0 = coeffs[0]
            let c1 = coeffs[1]
            let c2 = coeffs[2]
            var prev0 = values[0]
            var prev1 = values[1]
            var prev2 = values[2]
            var generated = 3
            while (generated < totalCount) {
                let nextValue = A.add(
                    A.add(A.mul(c0, prev0), A.mul(c1, prev1)),
                    A.mul(c2, prev2)
                )
                sum = A.add(sum, nextValue)
                prev0 = prev1
                prev1 = prev2
                prev2 = nextValue
                generated += 1
            }
            return sum
        }

        sum
    }

    func tryLinearRecurrenceSum(
        term: Expression_<A>,
        iteratorName: String,
        leftBound: A,
        rightBound: A
    ): Option<Expression_<A>> {
        if (this.usesIntegerDivision()) {
            return None
        }

        match (this.computeTermsCount(leftBound, rightBound)) {
            case Some(totalCount) =>
                if (totalCount <= 0) {
                    return Some(this.zeroExpression())
                }
                var order = 1
                while (order <= 3) {
                    let sampleCount = if (totalCount < 8) {
                        totalCount
                    } else {
                        8
                    }
                    if (sampleCount >= order * 2) {
                        match (this.collectSequenceValues(term, iteratorName, leftBound, sampleCount)) {
                            case Some(values) =>
                                match (this.tryFindLinearRecurrenceCoefficients(values, order)) {
                                    case Some(coeffs) =>
                                        let totalValue = this.evaluateSumByRecurrence(
                                            coeffs,
                                            values,
                                            totalCount,
                                            order
                                        )
                                        return Some(Constant(totalValue))
                                    case None => 0
                                }
                            case None => return None
                        }
                    }
                    order += 1
                }
                None
            case None => None
        }
    }

    func shiftIteratorExpr(iteratorName: String): Expression_<A> {
        Add(
            A.one(),
            HashMap<Expression_<A>, A>((Variable(iteratorName), A.one()),)
        ).toNormalForm()
    }

    func tryExtractTelescoping(
        term: Expression_<A>,
        iteratorName: String
    ): Option<(Expression_<A>, Int)> {
        let normalizedTerm = term.toNormalForm()
        match (normalizedTerm) {
            case Add(constantPart, terms) =>
                if (!A.isZero(constantPart) || terms.size != 2) {
                    return None
                }
                var plusTermOpt: Option<Expression_<A>> = None
                var minusTermOpt: Option<Expression_<A>> = None
                for ((singleTerm, coefficient) in terms) {
                    if (A.eq(coefficient, A.one())) {
                        plusTermOpt = Some(singleTerm)
                    } else if (A.eq(coefficient, A.fromInt(-1))) {
                        minusTermOpt = Some(singleTerm)
                    } else {
                        return None
                    }
                }

                match ((plusTermOpt, minusTermOpt)) {
                    case (Some(plusTerm), Some(minusTerm)) =>
                        let shiftExpr = this.shiftIteratorExpr(iteratorName)
                        let minusShifted = minusTerm
                            .substituteVariable(iteratorName, shiftExpr)
                            .toNormalForm()
                        if (minusShifted == plusTerm.toNormalForm()) {
                            return Some((minusTerm, 1))
                        }
                        let plusShifted = plusTerm
                            .substituteVariable(iteratorName, shiftExpr)
                            .toNormalForm()
                        if (plusShifted == minusTerm.toNormalForm()) {
                            return Some((plusTerm, -1))
                        }
                        None
                    case _ => None
                }
            case _ => None
        }
    }

    func tryTelescoping(
        term: Expression_<A>,
        iteratorName: String,
        leftBound: A,
        rightBound: A
    ): Option<Expression_<A>> {
        match (this.tryExtractTelescoping(term, iteratorName)) {
            case Some((baseTerm, orientation)) =>
                let rightPlusOne = A.add(rightBound, A.one())
                let leftExpr = baseTerm
                    .substituteVariable(iteratorName, Constant(leftBound))
                    .toNormalForm()
                let rightExpr = baseTerm
                    .substituteVariable(iteratorName, Constant(rightPlusOne))
                    .toNormalForm()
                let rawAns = if (orientation == 1) {
                    Add(
                        A.zero(),
                        HashMap<Expression_<A>, A>((rightExpr, A.one()), (leftExpr, A.fromInt(-1)))
                    ).toNormalForm()
                } else {
                    Add(
                        A.zero(),
                        HashMap<Expression_<A>, A>((leftExpr, A.one()), (rightExpr, A.fromInt(-1)))
                    ).toNormalForm()
                }
                match (this.evaluateConstantExpression(rawAns)) {
                    case Some(value) => Some(Constant(value))
                    case None => Some(rawAns)
                }
            case None => None
        }
    }

    func tryGeometricByRatio(
        term: Expression_<A>,
        iteratorName: String,
        leftBound: A,
        rightBound: A
    ): Option<(A, A)> {
        if (leftBound.compare(rightBound) == Ordering.GT) {
            return None
        }

        let secondBound = A.add(leftBound, A.one())

        match (this.evaluateTermAsConstant(term, iteratorName, leftBound)) {
            case Some(firstValue) =>
                if (secondBound.compare(rightBound) == Ordering.GT) {
                    match (this.scalarToNonNegativeInt(leftBound)) {
                        case Some(fromInt) =>
                            let q = A.one()
                            let qPowFrom = A.powInt(q, fromInt)
                            if (A.isZero(qPowFrom)) {
                                None
                            } else {
                                Some((A.div(firstValue, qPowFrom), q))
                            }
                        case None => None
                    }
                } else {
                    match (this.evaluateTermAsConstant(term, iteratorName, secondBound)) {
                        case Some(secondValue) =>
                            if (A.isZero(firstValue)) {
                                if (!A.isZero(secondValue)) {
                                    return None
                                }
                                var idx = secondBound
                                while (idx.compare(rightBound) != Ordering.GT) {
                                    match (this.evaluateTermAsConstant(term, iteratorName, idx)) {
                                        case Some(valueAtIdx) =>
                                            if (!A.isZero(valueAtIdx)) {
                                                return None
                                            }
                                        case None => return None
                                    }
                                    idx = A.add(idx, A.one())
                                }
                                return Some((A.zero(), A.one()))
                            }

                            let q = A.div(secondValue, firstValue)
                            var previousValue = secondValue
                            var idx = secondBound
                            while (idx.compare(rightBound) == Ordering.LT) {
                                let nextIdx = A.add(idx, A.one())
                                match (this.evaluateTermAsConstant(term, iteratorName, nextIdx)) {
                                    case Some(nextValue) =>
                                        if (!A.eq(nextValue, A.mul(previousValue, q))) {
                                            return None
                                        }
                                        previousValue = nextValue
                                        idx = nextIdx
                                    case None => return None
                                }
                            }

                            match (this.scalarToNonNegativeInt(leftBound)) {
                                case Some(fromInt) =>
                                    let qPowFrom = A.powInt(q, fromInt)
                                    if (A.isZero(qPowFrom)) {
                                        if (A.isZero(firstValue)) {
                                            Some((A.zero(), q))
                                        } else {
                                            None
                                        }
                                    } else {
                                        Some((A.div(firstValue, qPowFrom), q))
                                    }
                                case None => None
                            }
                        case None => None
                    }
                }
            case None => None
        }
    }

    func tryArithmeticProgression(
        term: Expression_<A>,
        iteratorName: String,
        leftBound: A,
        rightBound: A
    ): Option<Expression_<A>> {
        if (leftBound.compare(rightBound) == Ordering.GT) {
            return Some(this.zeroExpression())
        }

        match (this.computeTermsCount(leftBound, rightBound)) {
            case Some(totalCount) =>
                if (totalCount <= 0) {
                    return Some(this.zeroExpression())
                }
                match (this.evaluateTermAsConstant(term, iteratorName, leftBound)) {
                    case Some(firstValue) =>
                        if (totalCount == 1) {
                            return Some(Constant(firstValue))
                        }

                        let secondBound = A.add(leftBound, A.one())
                        match (this.evaluateTermAsConstant(term, iteratorName, secondBound)) {
                            case Some(secondValue) =>
                                let d = this.scalarSub(secondValue, firstValue)
                                var expected = secondValue
                                var current = secondBound
                                while (current.compare(rightBound) == Ordering.LT) {
                                    current = A.add(current, A.one())
                                    expected = A.add(expected, d)
                                    match (this.evaluateTermAsConstant(term, iteratorName, current)) {
                                        case Some(actualValue) =>
                                            if (!A.eq(actualValue, expected)) {
                                                return None
                                            }
                                        case None => return None
                                    }
                                }

                                let n = A.fromInt(totalCount)
                                let lastValue = expected
                                let two = A.fromInt(2)
                                let sum = A.div(
                                    A.mul(n, A.add(firstValue, lastValue)),
                                    two
                                )
                                Some(Constant(sum))
                            case None => None
                        }
                    case None => None
                }
            case None => None
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
                match (this.tryTelescoping(term, iteratorName, leftBound, rightBound)) {
                    case Some(telescopedValue) => telescopedValue
                    case None =>
                        match (this.extractAffineByIterator(term, iteratorName)) {
                            case Some((linear, bias)) =>
                                this.evaluateAffineClosedForm(linear, bias, leftBound, rightBound)
                            case None =>
                                match (this.tryGeometricByRatio(term, iteratorName, leftBound, rightBound)) {
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
                                        match (this.tryArithmeticProgression(term, iteratorName, leftBound, rightBound)) {
                                            case Some(arithmeticValue) => arithmeticValue
                                            case None =>
                                                match (this.tryLinearRecurrenceSum(term, iteratorName, leftBound, rightBound)) {
                                                    case Some(recurrenceValue) => recurrenceValue
                                                    case None =>
                                                        this.evaluateRangeSum(
                                                            term,
                                                            iteratorName,
                                                            leftBound,
                                                            rightBound
                                                        )
                                                }
                                        }
                                }
                        }
                }
        }
    }

    func buildPartialSum(
        term: Expression_<A>,
        iteratorName: String,
        fromExpr: Expression_<A>,
        toExpr: Expression_<A>
    ): Expression_<A> {
        Function(
            "partial_sum",
            ArrayList<Expression_<A>>([
                term.toNormalForm(),
                Variable(iteratorName),
                fromExpr.toNormalForm(),
                toExpr.toNormalForm()
            ])
        ).toNormalForm()
    }

    func scaleExpression(expr: Expression_<A>, coefficient: A): Expression_<A> {
        if (A.isZero(coefficient)) {
            return this.zeroExpression()
        }
        if (A.eq(coefficient, A.one())) {
            return expr.toNormalForm()
        }
        Add(
            A.zero(),
            HashMap<Expression_<A>, A>((expr.toNormalForm(), coefficient),)
        ).toNormalForm()
    }

    func rangeLengthExpression(
        fromExpr: Expression_<A>,
        toExpr: Expression_<A>
    ): Expression_<A> {
        Add(
            A.one(),
            HashMap<Expression_<A>, A>((toExpr.toNormalForm(), A.one()), (fromExpr.toNormalForm(), A.fromInt(-1)))
        ).toNormalForm()
    }

    func tryRewriteClosedFormNonAdd(
        term: Expression_<A>,
        iteratorName: String,
        fromExpr: Expression_<A>,
        toExpr: Expression_<A>
    ): Option<Expression_<A>> {
        let normalizedTerm = term.toNormalForm()
        match (this.extractGeometricParameters(normalizedTerm, iteratorName)) {
            case Some((a, q)) =>
                let geometricRules = GeometricRules<A>()
                return Some(
                    geometricRules.simplifyGeomSum(
                        ArrayList<Expression_<A>>([
                            Constant(a),
                            Constant(q),
                            fromExpr.toNormalForm(),
                            toExpr.toNormalForm()
                        ])
                    ).toNormalForm()
                )
            case None => 0
        }

        match (this.tryExtractTelescoping(normalizedTerm, iteratorName)) {
            case Some((baseTerm, orientation)) =>
                let leftExpr = baseTerm
                    .substituteVariable(iteratorName, fromExpr.toNormalForm())
                    .toNormalForm()
                let rightPlusOneExpr = Add(
                    A.one(),
                    HashMap<Expression_<A>, A>((toExpr.toNormalForm(), A.one()),)
                ).toNormalForm()
                let rightExpr = baseTerm
                    .substituteVariable(iteratorName, rightPlusOneExpr)
                    .toNormalForm()
                let closedForm = if (orientation == 1) {
                    Add(
                        A.zero(),
                        HashMap<Expression_<A>, A>((rightExpr, A.one()), (leftExpr, A.fromInt(-1)))
                    ).toNormalForm()
                } else {
                    Add(
                        A.zero(),
                        HashMap<Expression_<A>, A>((leftExpr, A.one()), (rightExpr, A.fromInt(-1)))
                    ).toNormalForm()
                }
                Some(closedForm)
            case None => None
        }
    }

    func simplifySymbolicByStructure(
        term: Expression_<A>,
        iteratorName: String,
        fromExpr: Expression_<A>,
        toExpr: Expression_<A>
    ): Expression_<A> {
        let normalizedTerm = term.toNormalForm()
        match (this.tryRewriteClosedFormNonAdd(normalizedTerm, iteratorName, fromExpr, toExpr)) {
            case Some(rewritten) => return rewritten.toNormalForm()
            case None => 0
        }
        match (normalizedTerm) {
            case Add(constantPart, terms) =>
                var result = this.zeroExpression()
                if (!A.isZero(constantPart)) {
                    let constContribution =
                        (Constant(constantPart) * this.rangeLengthExpression(fromExpr, toExpr))
                            .toNormalForm()
                    result = (result + constContribution).toNormalForm()
                }
                for ((singleTerm, coefficient) in terms) {
                    let childSum = this.simplifySymbolicByStructure(
                        singleTerm,
                        iteratorName,
                        fromExpr,
                        toExpr
                    )
                    result = (result + this.scaleExpression(childSum, coefficient)).toNormalForm()
                }
                result.toNormalForm()
            case _ =>
                this.buildPartialSum(
                    normalizedTerm,
                    iteratorName,
                    fromExpr,
                    toExpr
                )
        }
    }

    func simplifyConstantByStructure(
        term: Expression_<A>,
        iteratorName: String,
        leftBound: A,
        rightBound: A
    ): Expression_<A> {
        let normalizedTerm = term.toNormalForm()
        let fromExpr: Expression_<A> = Constant(leftBound)
        let toExpr: Expression_<A> = Constant(rightBound)
        match (this.tryTelescoping(normalizedTerm, iteratorName, leftBound, rightBound)) {
            case Some(telescopedValue) => return telescopedValue.toNormalForm()
            case None => 0
        }

        match (normalizedTerm) {
            case Add(constantPart, terms) =>
                var result = this.zeroExpression()
                if (!A.isZero(constantPart)) {
                    let constTermSum = this.evaluateAffineClosedForm(
                        A.zero(),
                        constantPart,
                        leftBound,
                        rightBound
                    )
                    result = (result + constTermSum).toNormalForm()
                }
                for ((singleTerm, coefficient) in terms) {
                    let childSum = this.simplifyConstantByStructure(
                        singleTerm,
                        iteratorName,
                        leftBound,
                        rightBound
                    )
                    result = (result + this.scaleExpression(childSum, coefficient)).toNormalForm()
                }
                result.toNormalForm()
            case _ =>
                match (this.tryRewriteClosedFormNonAdd(normalizedTerm, iteratorName, fromExpr, toExpr)) {
                    case Some(rewritten) => rewritten.toNormalForm()
                    case None =>
                        this.evaluateConstantBounds(
                            normalizedTerm,
                            iteratorName,
                            leftBound,
                            rightBound
                        )
                }
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
                        this.simplifyConstantByStructure(
                            term,
                            iteratorName,
                            leftBound,
                            rightBound
                        )
                    case _ =>
                        this.simplifySymbolicByStructure(
                            term,
                            iteratorName,
                            fromExpr,
                            toExpr
                        )
                }
            case _ => Function("partial_sum", normalizedArgs)
        }
    }
}
