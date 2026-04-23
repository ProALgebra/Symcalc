package symcalc
import std.collection.*
import std.time.*

func makePowI(base: Float64, iterator: Expression_<Float64>): Expression_<Float64> {
    Function<Float64>(
        "pow",
        ArrayList<Expression_<Float64>>([Constant(base), iterator])
    )
}

func makeShiftedI(i: Expression_<Float64>, shift: Float64): Expression_<Float64> {
    Add(
        shift,
        HashMap<Expression_<Float64>, Float64>((i, 1.0),)
    )
}

func makePartialSum(
    term: Expression_<Float64>,
    iterator: Expression_<Float64>,
    fromExpr: Expression_<Float64>,
    toExpr: Expression_<Float64>
): Expression_<Float64> {
    Function<Float64>(
        "partial_sum",
        ArrayList<Expression_<Float64>>([term, iterator, fromExpr, toExpr])
    )
}

func runOnePartialSumBench(
    core: Core<Float64>,
    id: Int64,
    name: String,
    expr: Expression_<Float64>,
    runs: Int64
) {
    println("BENCH_FORMULA|${id}|${name}|${expr.prettyPrint()}|${expr.toLatex()}")

    var lastResult = expr
    // Warmup to reduce first-call noise.
    let _ = core.simplifyExpression(expr)

    let start = MonoTime.now()
    var run: Int64 = 0
    while (run < runs) {
        lastResult = core.simplifyExpression(expr)
        run += 1
    }
    let end = MonoTime.now()

    let total = end - start
    let avg = total / runs
    println("BENCH_RESULT|${id}|${name}|runs=${runs}|total=${total}|avg=${avg}")
    println("BENCH_SIMPLIFIED|${id}|${lastResult.prettyPrint()}")
}

func runGrowthBenchmarkCase20(core: Core<Float64>) {
    let i = Variable<Float64>("i")
    let checkpoints = ArrayList<Float64>([
        10.0,
        100.0,
        1000.0,
        10000.0,
        50000.0,
        100000.0,
        250000.0,
        500000.0,
        1000000.0,
        1500000.0,
        2000000.0
    ])

    println("BENCH_FORMULA|20|growth_affine_heuristic|partial_sum(100 + i, i, 1, n)|\\\\operatorname{partial\\_sum}\\\\left(100 + i, i, 1, n\\\\right)")
    println("BENCH_GROWTH_HEADER|20|name=growth_affine_heuristic|columns=n,runs,total,avg,simplified")

    for (upper in checkpoints) {
        let runs = if (upper <= 1000.0) {
            100
        } else if (upper <= 100000.0) {
            40
        } else {
            10
        }

        let expr = makePartialSum(
            Add(100.0, HashMap<Expression_<Float64>, Float64>((i, 1.0),)),
            i,
            Constant(1.0),
            Constant(upper)
        )
        // Warmup for each point.
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

        println("BENCH_GROWTH_ROW|20|n=${upper}|runs=${runs}|total=${total}|avg=${avg}|simplified=${lastResult.prettyPrint()}")
    }
}

public func runPartialSumBenchmarks20() {
    let core = Core<Float64>()
    let i = Variable<Float64>("i")
    let n = Variable<Float64>("n")
    let m = Variable<Float64>("m")

    // Reusable terms.
    let iSquared = Multiply(
        1.0,
        HashMap<Expression_<Float64>, Float64>((i, 2.0),)
    )
    let iCubed = Multiply(
        1.0,
        HashMap<Expression_<Float64>, Float64>((i, 3.0),)
    )
    let iFourth = Multiply(
        1.0,
        HashMap<Expression_<Float64>, Float64>((i, 4.0),)
    )

    let gI = Function<Float64>("g", ArrayList<Expression_<Float64>>([i]))
    let gIPlusOne = Function<Float64>(
        "g",
        ArrayList<Expression_<Float64>>([makeShiftedI(i, 1.0)])
    )

    println("BENCHMARK_SUITE|partial_sum|cases=19")

    // 1. Geometric closed form, plain.
    runOnePartialSumBench(
        core,
        1,
        "geom_plain_2_times_3_pow_i_0_80",
        makePartialSum(
            Multiply(
                2.0,
                HashMap<Expression_<Float64>, Float64>((makePowI(3.0, i), 1.0),)
            ),
            i,
            Constant(0.0),
            Constant(80.0)
        ),
        20
    )

    // 2. Geometric with shifted exponent.
    runOnePartialSumBench(
        core,
        2,
        "geom_shifted_5_times_2_pow_i_minus_3_3_90",
        makePartialSum(
            Multiply(
                5.0,
                HashMap<Expression_<Float64>, Float64>((makePowI(2.0, makeShiftedI(i, -3.0)), 1.0),)
            ),
            i,
            Constant(3.0),
            Constant(90.0)
        ),
        20
    )

    // 3. Arithmetic progression.
    runOnePartialSumBench(
        core,
        3,
        "arithmetic_i_plus_2_1_10000",
        makePartialSum(
            Add(2.0, HashMap<Expression_<Float64>, Float64>((i, 1.0),)),
            i,
            Constant(1.0),
            Constant(10000.0)
        ),
        8
    )

    // 4. Quadratic polynomial (recurrence-friendly).
    runOnePartialSumBench(
        core,
        4,
        "quadratic_i2_plus_3i_plus_1_1_4000",
        makePartialSum(
            Add(
                1.0,
                HashMap<Expression_<Float64>, Float64>((iSquared, 1.0), (i, 3.0))
            ),
            i,
            Constant(1.0),
            Constant(4000.0)
        ),
        8
    )

    // 5. Telescoping g(i+1)-g(i), large range.
    runOnePartialSumBench(
        core,
        5,
        "telescoping_forward_g_i_plus_1_minus_g_i_1_200000",
        makePartialSum(
            Add(0.0, HashMap<Expression_<Float64>, Float64>((gIPlusOne, 1.0), (gI, -1.0))),
            i,
            Constant(1.0),
            Constant(200000.0)
        ),
        5
    )

    // 6. Telescoping reverse g(i)-g(i+1), large range.
    runOnePartialSumBench(
        core,
        6,
        "telescoping_reverse_g_i_minus_g_i_plus_1_1_200000",
        makePartialSum(
            Add(0.0, HashMap<Expression_<Float64>, Float64>((gI, 1.0), (gIPlusOne, -1.0))),
            i,
            Constant(1.0),
            Constant(200000.0)
        ),
        5
    )

    // 7. Symbolic bound geometric rewrite to geom_sum.
    runOnePartialSumBench(
        core,
        7,
        "symbolic_geom_to_geom_sum",
        makePartialSum(
            Multiply(
                2.0,
                HashMap<Expression_<Float64>, Float64>((makePowI(3.0, i), 1.0),)
            ),
            i,
            m,
            n
        ),
        100
    )

    // 8. Symbolic split by Add: constant + geom - 2*geom.
    runOnePartialSumBench(
        core,
        8,
        "symbolic_add_split_constant_plus_geom_minus_2geom",
        makePartialSum(
            Add(
                3.0,
                HashMap<Expression_<Float64>, Float64>((
                    makePowI(2.0, i),
                    1.0
                ), (
                    makePowI(5.0, i),
                    -2.0
                ))
            ),
            i,
            m,
            n
        ),
        100
    )

    // 9. Symbolic telescoping rewrite.
    runOnePartialSumBench(
        core,
        9,
        "symbolic_telescoping_forward",
        makePartialSum(
            Add(0.0, HashMap<Expression_<Float64>, Float64>((gIPlusOne, 1.0), (gI, -1.0))),
            i,
            m,
            n
        ),
        100
    )

    // 10. Symbolic non-recognized polynomial (stays partial_sum).
    runOnePartialSumBench(
        core,
        10,
        "symbolic_polynomial_stays_symbolic",
        makePartialSum(
            Add(
                1.0,
                HashMap<Expression_<Float64>, Float64>((iSquared, 1.0), (i, 2.0))
            ),
            i,
            m,
            n
        ),
        100
    )

    // 11. Constant q=1 geometric via ratio (constant term).
    runOnePartialSumBench(
        core,
        11,
        "constant_term_q_equals_1_7_2_500000",
        makePartialSum(
            Constant(7.0),
            i,
            Constant(2.0),
            Constant(500000.0)
        ),
        5
    )

    // 12. Geometric ratio detection with shifted exponent.
    runOnePartialSumBench(
        core,
        12,
        "geom_ratio_shifted_6_times_3_pow_i_minus_1_1_120",
        makePartialSum(
            Multiply(
                6.0,
                HashMap<Expression_<Float64>, Float64>((makePowI(3.0, makeShiftedI(i, -1.0)), 1.0),)
            ),
            i,
            Constant(1.0),
            Constant(120.0)
        ),
        20
    )

    // 13. Cubic polynomial.
    runOnePartialSumBench(
        core,
        13,
        "cubic_i3_plus_2i_plus_1_1_2000",
        makePartialSum(
            Add(
                1.0,
                HashMap<Expression_<Float64>, Float64>((iCubed, 1.0), (i, 2.0))
            ),
            i,
            Constant(1.0),
            Constant(2000.0)
        ),
        8
    )

    // 14. Quartic polynomial.
    runOnePartialSumBench(
        core,
        14,
        "quartic_i4_minus_3i2_plus_5_1_600",
        makePartialSum(
            Add(
                5.0,
                HashMap<Expression_<Float64>, Float64>((iFourth, 1.0), (iSquared, -3.0))
            ),
            i,
            Constant(1.0),
            Constant(600.0)
        ),
        8
    )

    // 15. Empty range.
    runOnePartialSumBench(
        core,
        15,
        "empty_range_10_5",
        makePartialSum(
            Add(2.0, HashMap<Expression_<Float64>, Float64>((i, 1.0),)),
            i,
            Constant(10.0),
            Constant(5.0)
        ),
        30
    )

    // 16. Single point.
    runOnePartialSumBench(
        core,
        16,
        "single_point_42_42",
        makePartialSum(
            Add(
                3.0,
                HashMap<Expression_<Float64>, Float64>((iSquared, 2.0), (i, -4.0))
            ),
            i,
            Constant(42.0),
            Constant(42.0)
        ),
        30
    )

    // 18. Large arithmetic linear.
    runOnePartialSumBench(
        core,
        18,
        "arithmetic_large_i_plus_100_1_2000000",
        makePartialSum(
            Add(100.0, HashMap<Expression_<Float64>, Float64>((i, 1.0),)),
            i,
            Constant(1.0),
            Constant(2000000.0)
        ),
        4
    )

    // 19. Large quadratic.
    runOnePartialSumBench(
        core,
        19,
        "quadratic_large_i2_plus_i_1_150000",
        makePartialSum(
            Add(0.0, HashMap<Expression_<Float64>, Float64>((iSquared, 1.0), (i, 1.0))),
            i,
            Constant(1.0),
            Constant(150000.0)
        ),
        4
    )

    // 20. Growth benchmark for presentation graph: n from 10 to 2,000,000.
    runGrowthBenchmarkCase20(core)

    println("BENCHMARK_SUITE_DONE|partial_sum|cases=19")
}
