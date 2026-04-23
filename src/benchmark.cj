package symcalc
import std.collection.*
import std.time.*

func runSinBatch(
    core: Core<ConstructiveReal>,
    label: String,
    inputs: ArrayList<ConstructiveReal>,
    runs: Int64,
    printValues: Bool
) {
    println("benchmark cj: ${label} (sin), items=${inputs.size}, runs=${runs}")
    let start = MonoTime.now()
    var run: Int64 = 0
    while (run < runs) {
        var index = 1
        for (arg in inputs) {
            let expr = Function<ConstructiveReal>(
                "sin",
                ArrayList<Expression_<ConstructiveReal>>([Constant(arg)])
            )
            let simplified = core.simplifyExpression(expr)
            if (printValues) {
                match (simplified) {
                    case Constant(v) =>
                        println("sin #${index} arg=${arg} => ${v.toDecimalString(30)}")
                    case _ =>
                        println("sin #${index} arg=${arg} => ${simplified}")
                }
            }
            index += 1
        }
        run += 1
    }
    let end = MonoTime.now()
    println("benchmark cj: ${label} (sin) time: ${end - start}")
}

func runCosBatch(
    core: Core<ConstructiveReal>,
    label: String,
    inputs: ArrayList<ConstructiveReal>,
    runs: Int64
) {
    println("benchmark cj: ${label} (cos), items=${inputs.size}, runs=${runs}")
    let start = MonoTime.now()
    var run: Int64 = 0
    while (run < runs) {
        for (arg in inputs) {
            let expr = Function<ConstructiveReal>(
                "cos",
                ArrayList<Expression_<ConstructiveReal>>([Constant(arg)])
            )
            let _ = core.simplifyExpression(expr)
        }
        run += 1
    }
    let end = MonoTime.now()
    println("benchmark cj: ${label} (cos) time: ${end - start}")
}

func runArithmeticBatch(
    core: Core<ConstructiveReal>,
    label: String,
    exprs: ArrayList<Expression_<ConstructiveReal>>,
    runs: Int64,
    printValues: Bool
) {
    println("benchmark cj: ${label} (arithmetic), items=${exprs.size}, runs=${runs}")
    let start = MonoTime.now()
    var run: Int64 = 0
    while (run < runs) {
        var index = 1
        for (expr in exprs) {
            let simplified = core.simplifyExpression(expr)
            if (printValues) {
                match (simplified) {
                    case Constant(v) =>
                        println("expr #${index}: ${expr} => ${v} (dec=${v.toDecimalString(30)})")
                    case _ =>
                        println("expr #${index}: ${expr} => ${simplified}")
                }
            }
            index += 1
        }
        run += 1
    }
    let end = MonoTime.now()
    println("benchmark cj: ${label} (arithmetic) time: ${end - start}")
}

func runMixedExpressionBatch(
    core: Core<ConstructiveReal>,
    label: String,
    runs: Int64
) {
    let x = Variable<ConstructiveReal>("x")
    let xSquared = Multiply(
        ConstructiveReal.one(),
        HashMap<Expression_<ConstructiveReal>, ConstructiveReal>((x, ConstructiveReal.fromInt(2)),)
    )
    let sinX2Plus1 = Function<ConstructiveReal>(
        "sin",
        ArrayList<Expression_<ConstructiveReal>>([
            Add(
                ConstructiveReal.one(),
                HashMap<Expression_<ConstructiveReal>, ConstructiveReal>((xSquared, ConstructiveReal.one()),)
            )
        ])
    )
    let xPlusHalf = Add(
        ConstructiveReal.fromFraction(1, 2),
        HashMap<Expression_<ConstructiveReal>, ConstructiveReal>((x, ConstructiveReal.one()),)
    )
    let cosXPlusHalf = Function<ConstructiveReal>(
        "cos",
        ArrayList<Expression_<ConstructiveReal>>([xPlusHalf])
    )

    println("benchmark cj: ${label} (mixed symbolic+numeric), runs=${runs}")
    let start = MonoTime.now()
    var run: Int64 = 0
    while (run < runs) {
        let dsin = core.derivativeExpression(sinX2Plus1, x)
        let dcos = core.derivativeExpression(cosXPlusHalf, x)
        let _ = core.simplifyExpression(
            core.substituteVariable(dsin, "x", Constant(ConstructiveReal.fromFraction(1, 2)))
        )
        let _ = core.simplifyExpression(
            core.substituteVariable(dcos, "x", Constant(ConstructiveReal.fromFraction(3, 5)))
        )
        run += 1
    }
    let end = MonoTime.now()
    println("benchmark cj: ${label} (mixed symbolic+numeric) time: ${end - start}")
}

func runConstructiveRealBenchmark() {
    let core = Core<ConstructiveReal>()
    core.setFunctionRules(makeConstructiveRealRules())

    let baseSinInputs = ArrayList<ConstructiveReal>([
        ConstructiveReal.fromFraction(1, 10),
        ConstructiveReal.fromFraction(1, 6),
        ConstructiveReal.fromFraction(1, 4),
        ConstructiveReal.fromFraction(1, 3),
        ConstructiveReal.fromFraction(1, 2),
        ConstructiveReal.fromFraction(2, 3),
        ConstructiveReal.fromFraction(3, 4),
        ConstructiveReal.fromFraction(4, 5),
        ConstructiveReal.fromFraction(5, 4),
        ConstructiveReal.fromFraction(7, 5)
    ])

    let extendedSinInputs = ArrayList<ConstructiveReal>([
        ConstructiveReal.fromFraction(1, 10),
        ConstructiveReal.fromFraction(1, 9),
        ConstructiveReal.fromFraction(1, 8),
        ConstructiveReal.fromFraction(1, 7),
        ConstructiveReal.fromFraction(1, 6),
        ConstructiveReal.fromFraction(1, 5),
        ConstructiveReal.fromFraction(1, 4),
        ConstructiveReal.fromFraction(1, 3),
        ConstructiveReal.fromFraction(1, 2),
        ConstructiveReal.fromFraction(3, 5),
        ConstructiveReal.fromFraction(2, 3),
        ConstructiveReal.fromFraction(3, 4),
        ConstructiveReal.fromFraction(4, 5),
        ConstructiveReal.fromFraction(5, 6),
        ConstructiveReal.fromFraction(7, 8),
        ConstructiveReal.fromFraction(9, 10),
        ConstructiveReal.fromFraction(11, 10),
        ConstructiveReal.fromFraction(6, 5),
        ConstructiveReal.fromFraction(5, 4),
        ConstructiveReal.fromFraction(7, 5)
    ])

    let arithmeticExprs = ArrayList<Expression_<ConstructiveReal>>([
        Add(
            ConstructiveReal.fromFraction(1, 3),
            HashMap<Expression_<ConstructiveReal>, ConstructiveReal>(
                (Constant(ConstructiveReal.fromFraction(1, 2)), ConstructiveReal.one()),
            )
        ),
        Multiply(
            ConstructiveReal.fromFraction(2, 3),
            HashMap<Expression_<ConstructiveReal>, ConstructiveReal>(
                (Constant(ConstructiveReal.fromFraction(3, 5)), ConstructiveReal.one()),
            )
        ),
        Function(
            "pow",
            ArrayList<Expression_<ConstructiveReal>>([
                Constant(ConstructiveReal.fromFraction(3, 2)),
                Constant(ConstructiveReal.fromInt(5))
            ])
        ),
        Add(
            ConstructiveReal.zero(),
            HashMap<Expression_<ConstructiveReal>, ConstructiveReal>(
                (Constant(ConstructiveReal.fromFraction(7, 8)), ConstructiveReal.one()),
                (Constant(ConstructiveReal.fromFraction(5, 6)), ConstructiveReal.one())
            )
        ),
        Multiply(
            ConstructiveReal.fromFraction(9, 10),
            HashMap<Expression_<ConstructiveReal>, ConstructiveReal>(
                (Constant(ConstructiveReal.fromFraction(10, 9)), ConstructiveReal.one()),
            )
        ),
        Add(
            ConstructiveReal.fromFraction(13, 21),
            HashMap<Expression_<ConstructiveReal>, ConstructiveReal>(
                (Constant(ConstructiveReal.fromFraction(17, 19)), ConstructiveReal.one()),
            )
        ),
        Multiply(
            ConstructiveReal.fromFraction(11, 13),
            HashMap<Expression_<ConstructiveReal>, ConstructiveReal>(
                (Constant(ConstructiveReal.fromFraction(23, 29)), ConstructiveReal.one()),
            )
        ),
        Function(
            "pow",
            ArrayList<Expression_<ConstructiveReal>>([
                Constant(ConstructiveReal.fromFraction(7, 5)),
                Constant(ConstructiveReal.fromInt(8))
            ])
        )
    ])

    println("benchmark cj: profile baseline")
    runSinBatch(core, "baseline", baseSinInputs, 10, true)
    runCosBatch(core, "baseline", baseSinInputs, 1)
    runArithmeticBatch(core, "baseline", arithmeticExprs, 1, true)
    runMixedExpressionBatch(core, "baseline", 1)

    println("benchmark cj: profile medium")
    runSinBatch(core, "medium", extendedSinInputs, 1, false)
    runCosBatch(core, "medium", extendedSinInputs, 1)
    runArithmeticBatch(core, "medium", arithmeticExprs, 1, false)
    runMixedExpressionBatch(core, "medium", 10)

    println("benchmark cj: profile heavy")
    runSinBatch(core, "heavy", extendedSinInputs, 1, false)
    runCosBatch(core, "heavy", extendedSinInputs, 1)
    runArithmeticBatch(core, "heavy", arithmeticExprs, 1, false)
    runMixedExpressionBatch(core, "heavy", 10)
}
