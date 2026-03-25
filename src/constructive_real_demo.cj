package symcalc
import std.collection.*
import std.time.*

func makeConstructiveRealRules(): FunctionRules<ConstructiveReal> {
    let rules = FunctionRules<ConstructiveReal>()
    rules.registerSimplifyRule("pi", { args =>
        if (args.isEmpty()) {
            Function("pi", ArrayList<Expression_<ConstructiveReal>>([]))
        } else {
            Function("pi", args)
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
