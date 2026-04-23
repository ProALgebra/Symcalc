package symcalc
import std.collection.*
import std.time.*
import std.math.numeric.BigInt

func crAbsValue(value: ConstructiveReal): ConstructiveReal {
    if (value.compare(ConstructiveReal.zero()) == Ordering.LT) {
        ConstructiveReal.mul(ConstructiveReal.fromInt(-1), value)
    } else {
        value
    }
}

func crEpsilonFromDecimalDigits(digits: Int): ConstructiveReal {
    if (digits <= 0) {
        return ConstructiveReal.one()
    }
    let denominator = BigInt.powInt(BigInt(10), digits)
    ConstructiveReal.fromBigIntFraction(BigInt(1), denominator)
}

func sinTaylorAdaptive(
    x: ConstructiveReal,
    epsilon: ConstructiveReal,
    maxTerms: Int
): ConstructiveReal {
    var sum = x
    var term = x
    let xSquared = ConstructiveReal.mul(x, x)
    var n = 1
    while (n < maxTerms) {
        let denominator = ConstructiveReal.fromInt((2 * n) * (2 * n + 1))
        term = ConstructiveReal.div(
            ConstructiveReal.mul(ConstructiveReal.fromInt(-1), ConstructiveReal.mul(term, xSquared)),
            denominator
        )
        sum = ConstructiveReal.add(sum, term)
        if (crAbsValue(term).compare(epsilon) != Ordering.GT) {
            break
        }
        n += 1
    }
    sum
}

func cosTaylorAdaptive(
    x: ConstructiveReal,
    epsilon: ConstructiveReal,
    maxTerms: Int
): ConstructiveReal {
    var sum = ConstructiveReal.one()
    var term = ConstructiveReal.one()
    let xSquared = ConstructiveReal.mul(x, x)
    var n = 1
    while (n < maxTerms) {
        let denominator = ConstructiveReal.fromInt((2 * n - 1) * (2 * n))
        term = ConstructiveReal.div(
            ConstructiveReal.mul(ConstructiveReal.fromInt(-1), ConstructiveReal.mul(term, xSquared)),
            denominator
        )
        sum = ConstructiveReal.add(sum, term)
        if (crAbsValue(term).compare(epsilon) != Ordering.GT) {
            break
        }
        n += 1
    }
    sum
}

func makeConstructiveRealRules(): FunctionRules<ConstructiveReal> {
    let rules = FunctionRules<ConstructiveReal>()
    rules.ensureDefaults()

    rules.registerSimplifyRule("pi", { args =>
        if (args.isEmpty()) {
            Function("pi", ArrayList<Expression_<ConstructiveReal>>([]))
        } else {
            Function("pi", args)
        }
    })

    rules.registerSimplifyRule("sin", { args =>
        if (args.size == 1) {
            let x = args[0].toNormalForm()
            match (x) {
                case Constant(value) =>
                    Constant(sinTaylorAdaptive(value, crEpsilonFromDecimalDigits(45), 300))
                case _ =>
                    Function("sin", ArrayList<Expression_<ConstructiveReal>>([x]))
            }
        } else {
            Function("sin", args)
        }
    })

    rules.registerSimplifyRule("cos", { args =>
        if (args.size == 1) {
            let x = args[0].toNormalForm()
            match (x) {
                case Constant(value) =>
                    Constant(cosTaylorAdaptive(value, crEpsilonFromDecimalDigits(45), 300))
                case _ =>
                    Function("cos", ArrayList<Expression_<ConstructiveReal>>([x]))
            }
        } else {
            Function("cos", args)
        }
    })
    rules
}

func runConstructiveRealCoreDemo() {
    let core = Core<ConstructiveReal>()
    core.setFunctionRules(makeConstructiveRealRules())

    let x = Variable<ConstructiveReal>("x")
    let one = Constant(ConstructiveReal.fromInt(1))

    let xSquared = Multiply(
        ConstructiveReal.one(),
        HashMap<Expression_<ConstructiveReal>, ConstructiveReal>((x, ConstructiveReal.fromInt(2)),)
    )
    let sinComposite = Function<ConstructiveReal>(
        "sin",
        ArrayList<Expression_<ConstructiveReal>>([
            Add(
                ConstructiveReal.one(),
                HashMap<Expression_<ConstructiveReal>, ConstructiveReal>((xSquared, ConstructiveReal.one()),)
            )
        ])
    )

    let derivativeStart = MonoTime.now()
    let derivative = core.derivativeExpression(sinComposite, x)
    let derivativeEnd = MonoTime.now()

    let evalStart = MonoTime.now()
    let valueAtHalf = core.simplifyExpression(
        core.substituteVariable(
            sinComposite,
            "x",
            Constant(ConstructiveReal.fromFraction(1, 2))
        )
    )
    let evalEnd = MonoTime.now()

    let piExpr = Function<ConstructiveReal>("pi", ArrayList<Expression_<ConstructiveReal>>([]))
    let twoPiExpr = Multiply(
        ConstructiveReal.fromInt(2),
        HashMap<Expression_<ConstructiveReal>, ConstructiveReal>((piExpr, ConstructiveReal.one()),)
    )
    let sinTwoPi = core.simplifyExpression(
        Function<ConstructiveReal>("sin", ArrayList<Expression_<ConstructiveReal>>([twoPiExpr]))
    )
    let cosPi = core.simplifyExpression(
        Function<ConstructiveReal>("cos", ArrayList<Expression_<ConstructiveReal>>([piExpr]))
    )

    println("constructive real: sin(x^2 + 1) expr: ${sinComposite}")
    println("constructive real: d/dx sin(x^2 + 1): ${derivative}")
    println("constructive real: d/dx time: ${derivativeEnd - derivativeStart}")
    println("constructive real: sin(x^2 + 1) at x=1/2: ${valueAtHalf}")
    println("constructive real: evaluate time: ${evalEnd - evalStart}")
    println("constructive real: sin(2*pi): ${sinTwoPi}")
    println("constructive real: cos(pi): ${cosPi}")
    println("constructive real: one: ${one}")
}
