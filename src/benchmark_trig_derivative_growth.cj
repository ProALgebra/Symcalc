package symcalc
import std.collection.*
import std.time.*

func buildNestedUnaryConst(
    functionName: String,
    seed: Expression_<Float64>,
    depth: Int64
): Expression_<Float64> {
    var expr = seed
    var i: Int64 = 0
    while (i < depth) {
        expr = Function<Float64>(
            functionName,
            ArrayList<Expression_<Float64>>([expr])
        )
        i += 1
    }
    expr
}

func buildNestedUnaryVar(
    functionName: String,
    seed: Expression_<Float64>,
    depth: Int64
): Expression_<Float64> {
    var expr = seed
    var i: Int64 = 0
    while (i < depth) {
        expr = Function<Float64>(
            functionName,
            ArrayList<Expression_<Float64>>([expr])
        )
        i += 1
    }
    expr
}

func runTrigGrowthSin(core: Core<Float64>) {
    let checkpoints = ArrayList<Int64>([1, 2, 4, 8, 12, 16, 20, 24, 28, 32])
    let seed = Constant(0.5)

    println("BENCH_FORMULA|21|growth_nested_sin_const|sin^n(0.5)|\\\\sin^{(n)}(0.5)")
    println("BENCH_GROWTH_HEADER|21|name=growth_nested_sin_const|columns=n,runs,total,avg,simplified")

    for (depth in checkpoints) {
        let runs = if (depth <= 8) {
            150
        } else if (depth <= 20) {
            100
        } else {
            60
        }

        let expr = buildNestedUnaryConst("sin", seed, depth)
        let _ = core.simplifyExpression(expr)

        var lastResult = expr
        let start = MonoTime.now()
        var run: Int64 = 0
        while (run < runs) {
            lastResult = core.simplifyExpression(expr)
            run += 1
        }
        let end = MonoTime.now()
        let total = end - start
        let avg = total / runs
        println("BENCH_GROWTH_ROW|21|n=${depth}|runs=${runs}|total=${total}|avg=${avg}|simplified=${lastResult.prettyPrint()}")
    }
}

func runTrigGrowthCos(core: Core<Float64>) {
    let checkpoints = ArrayList<Int64>([1, 2, 4, 8, 12, 16, 20, 24, 28, 32])
    let seed = Constant(0.5)

    println("BENCH_FORMULA|22|growth_nested_cos_const|cos^n(0.5)|\\\\cos^{(n)}(0.5)")
    println("BENCH_GROWTH_HEADER|22|name=growth_nested_cos_const|columns=n,runs,total,avg,simplified")

    for (depth in checkpoints) {
        let runs = if (depth <= 8) {
            150
        } else if (depth <= 20) {
            100
        } else {
            60
        }

        let expr = buildNestedUnaryConst("cos", seed, depth)
        let _ = core.simplifyExpression(expr)

        var lastResult = expr
        let start = MonoTime.now()
        var run: Int64 = 0
        while (run < runs) {
            lastResult = core.simplifyExpression(expr)
            run += 1
        }
        let end = MonoTime.now()
        let total = end - start
        let avg = total / runs
        println("BENCH_GROWTH_ROW|22|n=${depth}|runs=${runs}|total=${total}|avg=${avg}|simplified=${lastResult.prettyPrint()}")
    }
}

func runDerivativeGrowth(core: Core<Float64>) {
    let checkpoints = ArrayList<Int64>([1, 2, 3, 4, 5, 6, 7, 8, 10, 12])
    let x = Variable<Float64>("x")

    println("BENCH_FORMULA|23|growth_derivative_nested_sin_x|d/dx sin^n(x) at x=0.5|\\\\left.\\\\frac{d}{dx}\\\\sin^{(n)}(x)\\\\right|_{x=0.5}")
    println("BENCH_GROWTH_HEADER|23|name=growth_derivative_nested_sin_x|columns=n,runs,total,avg,simplified")

    for (depth in checkpoints) {
        let runs = if (depth <= 5) {
            30
        } else if (depth <= 8) {
            18
        } else {
            10
        }

        let expr = buildNestedUnaryVar("sin", x, depth)
        let _ = core.derivativeExpression(expr, x)

        var lastResult: Expression_<Float64> = expr
        let start = MonoTime.now()
        var run: Int64 = 0
        while (run < runs) {
            let d = core.derivativeExpression(expr, x)
            let atHalf = core.substituteVariable(d, "x", Constant(0.5))
            lastResult = core.simplifyExpression(atHalf)
            run += 1
        }
        let end = MonoTime.now()
        let total = end - start
        let avg = total / runs
        println("BENCH_GROWTH_ROW|23|n=${depth}|runs=${runs}|total=${total}|avg=${avg}|simplified=${lastResult.prettyPrint()}")
    }
}

func buildDerivativeComplexWidthExpr(width: Int64): Expression_<Float64> {
    let x = Variable<Float64>("x")
    let powConstA = Function<Float64>(
        "pow",
        ArrayList<Expression_<Float64>>([Constant(2.0), Constant(5.0)])
    )
    let powConstB = Function<Float64>(
        "pow",
        ArrayList<Expression_<Float64>>([Constant(3.0), Constant(4.0)])
    )

    var expr: Expression_<Float64> = Add(0.0, HashMap<Expression_<Float64>, Float64>())
    var idx: Int64 = 0
    while (idx < width) {
        let yj = Variable<Float64>("y${idx}")
        let xPlusYj = Add(
            0.0,
            HashMap<Expression_<Float64>, Float64>((x, 1.0), (yj, 1.0))
        )
        let xPlusYjSquared = Multiply(
            1.0,
            HashMap<Expression_<Float64>, Float64>((xPlusYj, 2.0),)
        )
        let lnArg = Add(
            1.0,
            HashMap<Expression_<Float64>, Float64>((xPlusYjSquared, 1.0),)
        )
        let scaledA = Multiply(
            1.0,
            HashMap<Expression_<Float64>, Float64>((powConstA, 1.0), (xPlusYj, 1.0))
        )
        let scaledB = Multiply(
            1.0,
            HashMap<Expression_<Float64>, Float64>((powConstB, 1.0), (xPlusYj, 1.0))
        )

        let termSin = Function<Float64>("sin", ArrayList<Expression_<Float64>>([xPlusYj]))
        let termCosExp = Function<Float64>(
            "cos",
            ArrayList<Expression_<Float64>>([
                Function<Float64>("exp", ArrayList<Expression_<Float64>>([xPlusYj]))
            ])
        )
        let termLn = Function<Float64>("ln", ArrayList<Expression_<Float64>>([lnArg]))
        let termExp = Function<Float64>("exp", ArrayList<Expression_<Float64>>([scaledA]))
        let termSinPow = Function<Float64>("sin", ArrayList<Expression_<Float64>>([scaledB]))

        expr = (expr + termSin + termCosExp + termLn + termExp + termSinPow).toNormalForm()
        idx += 1
    }
    expr.toNormalForm()
}

func runDerivativeComplexWidthGrowth(core: Core<Float64>) {
    let checkpoints = ArrayList<Int64>([1, 2, 3, 4, 6, 8, 10, 12, 14, 16])
    let x = Variable<Float64>("x")

    println("BENCH_FORMULA|24|growth_derivative_complex_width|d/dx sum_j f_j(x,y_j), f_j includes sin/cos/exp/ln/pow|\\\\frac{d}{dx}\\\\sum_j f_j(x,y_j)")
    println("BENCH_GROWTH_HEADER|24|name=growth_derivative_complex_width|columns=n,runs,total,avg,simplified")

    for (width in checkpoints) {
        let runs = if (width <= 4) {
            20
        } else if (width <= 10) {
            12
        } else {
            8
        }

        let expr = buildDerivativeComplexWidthExpr(width)
        let _ = core.derivativeExpression(expr, x)

        var lastResult: Expression_<Float64> = expr
        let start = MonoTime.now()
        var run: Int64 = 0
        while (run < runs) {
            let d = core.derivativeExpression(expr, x)
            let atHalf = core.substituteVariable(d, "x", Constant(0.5))
            lastResult = core.simplifyExpression(atHalf)
            run += 1
        }
        let end = MonoTime.now()
        let total = end - start
        let avg = total / runs
        println("BENCH_GROWTH_ROW|24|n=${width}|runs=${runs}|total=${total}|avg=${avg}|simplified=${lastResult.prettyPrint()}")
    }
}

func buildSubstitutionStressExpr(depth: Int64, width: Int64): Expression_<Float64> {
    let x = Variable<Float64>("x")
    var base: Expression_<Float64> = Add(0.0, HashMap<Expression_<Float64>, Float64>((x, 1.0),))

    var idx: Int64 = 0
    while (idx < width) {
        let uj = Variable<Float64>("u${idx}")
        let mixed = Add(
            0.0,
            HashMap<Expression_<Float64>, Float64>((x, 1.0), (uj, 1.0))
        )
        base = base + Function<Float64>("sin", ArrayList<Expression_<Float64>>([mixed]))
        base = base + Function<Float64>("cos", ArrayList<Expression_<Float64>>([mixed]))
        idx += 1
    }

    var expr = base
    var d: Int64 = 0
    while (d < depth) {
        expr = Add(
            1.0,
            HashMap<Expression_<Float64>, Float64>((
                Function<Float64>("sin", ArrayList<Expression_<Float64>>([expr])),
                1.0
            ), (
                Function<Float64>("cos", ArrayList<Expression_<Float64>>([expr])),
                1.0
            ), (
                x,
                1.0
            ))
        )
        d += 1
    }
    expr
}

func runSubstitutionMassiveGrowth() {
    let checkpoints = ArrayList<Int64>([1, 2, 3, 4, 5, 6, 7, 8])
    let replacement = Add(
        0.25,
        HashMap<Expression_<Float64>, Float64>((Variable<Float64>("z"), 1.0),)
    )

    println("BENCH_FORMULA|25|growth_substitute_massive|substitute x->(z+0.25) on deep wide expr (raw vs normalized)|x\\\\mapsto z+0.25")
    println("BENCH_GROWTH_HEADER|25|name=growth_substitute_massive|columns=n,runs,total_raw,avg_raw,total_norm,avg_norm")

    for (depth in checkpoints) {
        let runs = if (depth <= 4) { 30 } else { 15 }
        let rawExpr = buildSubstitutionStressExpr(depth, 8)
        let normExpr = rawExpr.toNormalForm()

        let _ = rawExpr.substituteVariable("x", replacement)
        let _ = normExpr.substituteVariable("x", replacement)

        let rawStart = MonoTime.now()
        var rawRun: Int64 = 0
        while (rawRun < runs) {
            let _ = rawExpr.substituteVariable("x", replacement)
            rawRun += 1
        }
        let rawEnd = MonoTime.now()

        let normStart = MonoTime.now()
        var normRun: Int64 = 0
        while (normRun < runs) {
            let _ = normExpr.substituteVariable("x", replacement)
            normRun += 1
        }
        let normEnd = MonoTime.now()

        let totalRaw = rawEnd - rawStart
        let avgRaw = totalRaw / runs
        let totalNorm = normEnd - normStart
        let avgNorm = totalNorm / runs
        println("BENCH_GROWTH_ROW|25|n=${depth}|runs=${runs}|total_raw=${totalRaw}|avg_raw=${avgRaw}|total_norm=${totalNorm}|avg_norm=${avgNorm}")
    }
}

public func runTrigAndDerivativeGrowthBenchmarks() {
    let core = Core<Float64>()
    println("BENCHMARK_SUITE|trig_derivative_growth|cases=5")
    runTrigGrowthSin(core)
    runTrigGrowthCos(core)
    runDerivativeGrowth(core)
    runDerivativeComplexWidthGrowth(core)
    runSubstitutionMassiveGrowth()
    println("BENCHMARK_SUITE_DONE|trig_derivative_growth|cases=5")
}
