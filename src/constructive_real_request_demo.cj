package symcalc
import std.collection.*
import std.time.*
import std.math.numeric.BigInt

func runConstructiveRealRequestDemo() {
    let core = Core<ConstructiveReal>()
    core.setFunctionRules(makeConstructiveRealRules())

    let x = Variable<ConstructiveReal>("x")
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

    let fullPipelineStart = MonoTime.now()
    let evalStart = MonoTime.now()
    let value = core.simplifyExpression(
        core.substituteVariable(
            sinComposite,
            "x",
            Constant(ConstructiveReal.fromFraction(1, 2))
        )
    )
    let evalEnd = MonoTime.now()

    let pureSinExpr = Function<ConstructiveReal>(
        "sin",
        ArrayList<Expression_<ConstructiveReal>>([Constant(ConstructiveReal.fromFraction(5, 4))])
    )
    let pureSinStart = MonoTime.now()
    let pureSinValue = core.simplifyExpression(pureSinExpr)
    let pureSinEnd = MonoTime.now()


    match (value) {
        case Constant(result) =>
            let precisionBits = 40
            let (low, high) = result.approximateDyadic(precisionBits)
            let scale = BigInt.powInt(BigInt(2), precisionBits)
            let decimalDigits = 30
            let decimalStart = MonoTime.now()
            let decimalValue = result.toDecimalString(decimalDigits)
            let decimalEnd = MonoTime.now()
            let fullPipelineEnd = MonoTime.now()
            println("request-demo approximation bits: ${precisionBits}")
            println("request-demo interval low : ${low}/${scale}")
            println("request-demo interval high: ${high}/${scale}")
            println("request-demo guaranteed error <= 1/2^${precisionBits}")
            println("request-demo decimal (${decimalDigits} digits): ${decimalValue}")
            println("request-demo decimal conversion time: ${decimalEnd - decimalStart}")
            println("request-demo full pipeline time (simplify+compute+decimal): ${fullPipelineEnd - fullPipelineStart}")
        case _ =>
            let fullPipelineEnd = MonoTime.now()
            println("request-demo: value is symbolic, no numeric approximation")
            println("request-demo full pipeline time (simplify+compute): ${fullPipelineEnd - fullPipelineStart}")
    }
}
