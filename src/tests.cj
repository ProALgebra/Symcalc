package symcalc
import std.collection.*

func assertExprEqualInt64(
    testName: String,
    actual: Expression_<Int64>,
    expected: Expression_<Int64>
): Bool {
    let left = actual.toNormalForm()
    let right = expected.toNormalForm()
    if (left == right) {
        return true
    }
    println("[FAIL] ${testName}")
    println("  expected: ${right}")
    println("  actual:   ${left}")
    false
}

func assertExprEqualFloat64(
    testName: String,
    actual: Expression_<Float64>,
    expected: Expression_<Float64>
): Bool {
    let left = actual.toNormalForm()
    let right = expected.toNormalForm()
    if (left == right) {
        return true
    }
    println("[FAIL] ${testName}")
    println("  expected: ${right}")
    println("  actual:   ${left}")
    false
}

func assertConstantInRange(
    testName: String,
    actual: Expression_<Float64>,
    low: Float64,
    high: Float64
): Bool {
    match (actual.toNormalForm()) {
        case Constant(value) =>
            if (value >= low && value <= high) {
                true
            } else {
                println("[FAIL] ${testName}")
                println("  expected in range: [${low}, ${high}]")
                println("  actual: ${value}")
                false
            }
        case Add(constantPart, terms) =>
            if (terms.isEmpty() && constantPart >= low && constantPart <= high) {
                true
            } else {
                println("[FAIL] ${testName}")
                println("  expected in range: [${low}, ${high}]")
                println("  actual: ${actual.toNormalForm()}")
                false
            }
        case _ =>
            println("[FAIL] ${testName}")
            println("  expected constant in range, actual: ${actual.toNormalForm()}")
            false
    }
}

public func runRegressionTests(): Bool {
    var allPassed = true

    let intCore = Core<Int64>()
    let floatCore = Core<Float64>()

    let iInt = Variable<Int64>("i")
    let partialSumExpr = Function<Int64>(
        "partial_sum",
        ArrayList<Expression_<Int64>>([
            Add(2, HashMap<Expression_<Int64>, Int64>((iInt, 1),)),
            iInt,
            Constant(1),
            Constant(4)
        ])
    )
    let partialSumActual = intCore.simplifyExpression(partialSumExpr)
    let partialSumExpected = Add(18, HashMap<Expression_<Int64>, Int64>())
    allPassed = allPassed && assertExprEqualInt64(
        "partial_sum(i+2, i, 1, 4) == 18",
        partialSumActual,
        partialSumExpected
    )

    let partialEmpty = Function<Int64>(
        "partial_sum",
        ArrayList<Expression_<Int64>>([
            Add(2, HashMap<Expression_<Int64>, Int64>((iInt, 1),)),
            iInt,
            Constant(5),
            Constant(4)
        ])
    )
    allPassed = allPassed && assertExprEqualInt64(
        "partial_sum empty range == 0",
        intCore.simplifyExpression(partialEmpty),
        Add(0, HashMap<Expression_<Int64>, Int64>())
    )

    let partialPoint = Function<Int64>(
        "partial_sum",
        ArrayList<Expression_<Int64>>([
            Add(2, HashMap<Expression_<Int64>, Int64>((iInt, 1),)),
            iInt,
            Constant(3),
            Constant(3)
        ])
    )
    allPassed = allPassed && assertExprEqualInt64(
        "partial_sum single point",
        intCore.simplifyExpression(partialPoint),
        Add(5, HashMap<Expression_<Int64>, Int64>())
    )

    let iFloat = Variable<Float64>("i")
    let geometricViaPartial = Function<Float64>(
        "partial_sum",
        ArrayList<Expression_<Float64>>([
            Multiply(
                2.0,
                HashMap<Expression_<Float64>, Float64>((
                    Function(
                        "pow",
                        ArrayList<Expression_<Float64>>([Constant(3.0), iFloat])
                    ),
                    1.0
                ),)
            ),
            iFloat,
            Constant(0.0),
            Constant(4.0)
        ])
    )
    let geometricDirect = Function<Float64>(
        "geom_sum",
        ArrayList<Expression_<Float64>>([
            Constant(2.0),
            Constant(3.0),
            Constant(0.0),
            Constant(4.0)
        ])
    )

    let geometricViaPartialActual = floatCore.simplifyExpression(geometricViaPartial)
    let geometricDirectActual = floatCore.simplifyExpression(geometricDirect)
    let geometricExpected = Constant(242.0)

    allPassed = allPassed && assertExprEqualFloat64(
        "partial_sum geometric == geom_sum",
        geometricViaPartialActual,
        geometricDirectActual
    )
    allPassed = allPassed && assertExprEqualFloat64(
        "geom_sum(2, 3, 0, 4) == 242",
        geometricDirectActual,
        geometricExpected
    )

    let geometricQOne = Function<Float64>(
        "geom_sum",
        ArrayList<Expression_<Float64>>([
            Constant(2.0),
            Constant(1.0),
            Constant(2.0),
            Constant(6.0)
        ])
    )
    allPassed = allPassed && assertExprEqualFloat64(
        "geom_sum with q=1",
        floatCore.simplifyExpression(geometricQOne),
        Constant(10.0)
    )

    let geometricEmpty = Function<Float64>(
        "geom_sum",
        ArrayList<Expression_<Float64>>([
            Constant(2.0),
            Constant(3.0),
            Constant(7.0),
            Constant(4.0)
        ])
    )
    allPassed = allPassed && assertExprEqualFloat64(
        "geom_sum empty range == 0",
        floatCore.simplifyExpression(geometricEmpty),
        Add(0.0, HashMap<Expression_<Float64>, Float64>())
    )

    let nonConstBounds = Function<Float64>(
        "partial_sum",
        ArrayList<Expression_<Float64>>([
            Multiply(
                2.0,
                HashMap<Expression_<Float64>, Float64>((
                    Function(
                        "pow",
                        ArrayList<Expression_<Float64>>([Constant(3.0), iFloat])
                    ),
                    1.0
                ),)
            ),
            iFloat,
            Variable<Float64>("n"),
            Constant(4.0)
        ])
    )
    allPassed = allPassed && assertExprEqualFloat64(
        "partial_sum with non-constant bound stays symbolic",
        floatCore.simplifyExpression(nonConstBounds),
        nonConstBounds.toNormalForm()
    )

    let symbolicGeom = Function<Float64>(
        "geom_sum",
        ArrayList<Expression_<Float64>>([
            Constant(2.0),
            Variable<Float64>("q"),
            Constant(0.0),
            Constant(4.0)
        ])
    )
    allPassed = allPassed && assertExprEqualFloat64(
        "geom_sum with symbolic q stays symbolic",
        floatCore.simplifyExpression(symbolicGeom),
        symbolicGeom.toNormalForm()
    )

    let pow0 = Function<Float64>(
        "pow",
        ArrayList<Expression_<Float64>>([Constant(2.0), Constant(0.0)])
    )
    let pow1 = Function<Float64>(
        "pow",
        ArrayList<Expression_<Float64>>([Constant(2.0), Constant(1.0)])
    )
    let pow5 = Function<Float64>(
        "pow",
        ArrayList<Expression_<Float64>>([Constant(2.0), Constant(5.0)])
    )
    let powSymbolic = Function<Float64>(
        "pow",
        ArrayList<Expression_<Float64>>([Constant(2.0), Variable<Float64>("k")])
    )
    let powNegative = Function<Float64>(
        "pow",
        ArrayList<Expression_<Float64>>([Constant(2.0), Constant(-1.0)])
    )

    allPassed = allPassed && assertExprEqualFloat64(
        "pow(2,0)=1",
        floatCore.simplifyExpression(pow0),
        Constant(1.0)
    )
    allPassed = allPassed && assertExprEqualFloat64(
        "pow(2,1)=2",
        floatCore.simplifyExpression(pow1),
        Constant(2.0)
    )
    allPassed = allPassed && assertExprEqualFloat64(
        "pow(2,5)=32",
        floatCore.simplifyExpression(pow5),
        Constant(32.0)
    )
    allPassed = allPassed && assertExprEqualFloat64(
        "pow(2,k) stays symbolic",
        floatCore.simplifyExpression(powSymbolic),
        powSymbolic.toNormalForm()
    )
    allPassed = allPassed && assertExprEqualFloat64(
        "pow(2,-1) stays symbolic",
        floatCore.simplifyExpression(powNegative),
        powNegative.toNormalForm()
    )

    let sinConst = Function<Float64>("sin", ArrayList<Expression_<Float64>>([Constant(1.0)]))
    let cosConst = Function<Float64>("cos", ArrayList<Expression_<Float64>>([Constant(3.1415)]))
    let sinSymbolic = Function<Float64>(
        "sin",
        ArrayList<Expression_<Float64>>([Variable<Float64>("x")])
    )

    let sinActual = floatCore.simplifyExpression(sinConst)
    let cosActual = floatCore.simplifyExpression(cosConst)
    let sinSymbolicActual = floatCore.simplifyExpression(sinSymbolic)
    let sinSymbolicExpected = Function<Float64>(
        "sin",
        ArrayList<Expression_<Float64>>([Variable<Float64>("x")])
    )

    allPassed = allPassed && assertConstantInRange(
        "sin(1) is approximately 0.841471",
        sinActual,
        0.841470,
        0.841472
    )
    allPassed = allPassed && assertConstantInRange(
        "cos(3.1415) is approximately -1",
        cosActual,
        -1.000001,
        -0.999999
    )
    allPassed = allPassed && assertExprEqualFloat64(
        "sin(0)=0",
        floatCore.simplifyExpression(
            Function<Float64>("sin", ArrayList<Expression_<Float64>>([Constant(0.0)]))
        ),
        Constant(0.0)
    )
    allPassed = allPassed && assertExprEqualFloat64(
        "cos(0)=1",
        floatCore.simplifyExpression(
            Function<Float64>("cos", ArrayList<Expression_<Float64>>([Constant(0.0)]))
        ),
        Constant(1.0)
    )
    allPassed = allPassed && assertExprEqualFloat64(
        "sin(x) stays symbolic",
        sinSymbolicActual,
        sinSymbolicExpected
    )
    let pi = Function<Float64>("pi", ArrayList<Expression_<Float64>>([]))
    let twoPi = Multiply(
        2.0,
        HashMap<Expression_<Float64>, Float64>((pi, 1.0),)
    )
    allPassed = allPassed && assertExprEqualFloat64(
        "sin(pi)=0",
        floatCore.simplifyExpression(
            Function<Float64>("sin", ArrayList<Expression_<Float64>>([pi]))
        ),
        Constant(0.0)
    )
    allPassed = allPassed && assertExprEqualFloat64(
        "sin(2*pi)=0",
        floatCore.simplifyExpression(
            Function<Float64>("sin", ArrayList<Expression_<Float64>>([twoPi]))
        ),
        Constant(0.0)
    )
    allPassed = allPassed && assertExprEqualFloat64(
        "cos(pi)=-1",
        floatCore.simplifyExpression(
            Function<Float64>("cos", ArrayList<Expression_<Float64>>([pi]))
        ),
        Constant(-1.0)
    )
    allPassed = allPassed && assertExprEqualFloat64(
        "cos(2*pi)=1",
        floatCore.simplifyExpression(
            Function<Float64>("cos", ArrayList<Expression_<Float64>>([twoPi]))
        ),
        Constant(1.0)
    )

    let x = Variable<Float64>("x")
    let sinX = Function<Float64>("sin", ArrayList<Expression_<Float64>>([x]))
    let cosX = Function<Float64>("cos", ArrayList<Expression_<Float64>>([x]))
    let dx = x.derivative(x).toNormalForm()
    let dSinXExpected =
        (Function<Float64>("cos", ArrayList<Expression_<Float64>>([x])) * dx).toNormalForm()
    let dCosXExpected = Multiply(
        -1.0,
        HashMap<Expression_<Float64>, Float64>((
            Function<Float64>("sin", ArrayList<Expression_<Float64>>([x])),
            1.0
        ),)
    )
    let dCosXExpectedWithDx = (dCosXExpected * dx).toNormalForm()

    allPassed = allPassed && assertExprEqualFloat64(
        "d/dx sin(x)=cos(x)",
        floatCore.derivativeExpression(sinX, x),
        dSinXExpected
    )
    allPassed = allPassed && assertExprEqualFloat64(
        "d/dx cos(x)=-sin(x)",
        floatCore.derivativeExpression(cosX, x),
        dCosXExpectedWithDx
    )

    if (allPassed) {
        println("[OK] All regression tests passed")
    }
    allPassed
}
