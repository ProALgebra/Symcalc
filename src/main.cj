package symcalc
import std.math.numeric.BigInt
import std.collection.*
import std.time.*

main() {
    let demoX = Variable<Float64>("x")
    let demoY = Variable<Float64>("y")
    let demoZ = Variable<Float64>("z")
    let demoI = Variable<Float64>("i")
    let demoExpr = Add(
        1.0,
        HashMap<Expression_<Float64>, Float64>((
            Multiply(2.0, HashMap<Expression_<Float64>, Float64>((demoX, 2.0),)),
            1.0
        ),)
    )
    println("pretty: ${demoExpr.prettyPrint()}")
    println("latex: ${demoExpr.toLatex()}")
    println("string: ${demoExpr.toString()}")

    let longPoly = Add(
        7.0,
        HashMap<Expression_<Float64>, Float64>(
            (Multiply(3.0, HashMap<Expression_<Float64>, Float64>((demoX, 3.0), (demoY, 2.0))), 1.0),
            (Multiply(-2.0, HashMap<Expression_<Float64>, Float64>((demoX, 1.0), (demoZ, 2.0))), 1.0),
            (Multiply(5.0, HashMap<Expression_<Float64>, Float64>((demoY, 4.0),)), 1.0),
            (Multiply(
                1.0,
                HashMap<Expression_<Float64>, Float64>(
                    (
                        Add(
                            1.0,
                            HashMap<Expression_<Float64>, Float64>(
                                (Multiply(2.0, HashMap<Expression_<Float64>, Float64>((demoX, 1.0))), 1.0),
                                (Multiply(1.0, HashMap<Expression_<Float64>, Float64>((demoY, 1.0))), 1.0)
                            )
                        ),
                        2.0
                    ),
                    (demoZ, 1.0)
                )
            ), 1.0)
        )
    )
    println("long string: ${longPoly.toString()}")
    println("long pretty: ${longPoly.prettyPrint()}")
    println("long latex: ${longPoly.toLatex()}")

    let demoPowX2 = Function<Float64>(
        "pow",
        ArrayList<Expression_<Float64>>([demoX, Constant(2.0)])
    )
    let demoSinNested = Function<Float64>(
        "sin",
        ArrayList<Expression_<Float64>>([
            Add(
                1.0,
                HashMap<Expression_<Float64>, Float64>(
                    (demoPowX2, 1.0),
                    (Function<Float64>("pi", ArrayList<Expression_<Float64>>([])), 1.0)
                )
            )
        ])
    )
    let demoExpLn = Function<Float64>(
        "exp",
        ArrayList<Expression_<Float64>>([
            Function<Float64>(
                "ln",
                ArrayList<Expression_<Float64>>([
                    Add(
                        3.0,
                        HashMap<Expression_<Float64>, Float64>((demoPowX2, 1.0),)
                    )
                ])
            )
        ])
    )
    let demoPartial = Function<Float64>(
        "partial_sum",
        ArrayList<Expression_<Float64>>([
            Multiply(
                2.0,
                HashMap<Expression_<Float64>, Float64>((
                    Function<Float64>(
                        "pow",
                        ArrayList<Expression_<Float64>>([Constant(3.0), demoI])
                    ),
                    1.0
                ),)
            ),
            demoI,
            Constant(0.0),
            Constant(5.0)
        ])
    )
    let demoGeom = Function<Float64>(
        "geom_sum",
        ArrayList<Expression_<Float64>>([
            Function<Float64>("cos", ArrayList<Expression_<Float64>>([demoX])),
            Constant(2.0),
            Constant(1.0),
            Constant(4.0)
        ])
    )

    println("pretty nested: ${demoSinNested.prettyPrint()}")
    println("latex nested: ${demoSinNested.toLatex()}")
    println("string nested: ${demoSinNested.toString()}")
    println("pretty exp-ln: ${demoExpLn.prettyPrint()}")
    println("latex exp-ln: ${demoExpLn.toLatex()}")
    println("string exp-ln: ${demoExpLn.toString()}")
    println("pretty partial: ${demoPartial.prettyPrint()}")
    println("latex partial: ${demoPartial.toLatex()}")
    println("string partial: ${demoPartial.toString()}")
    println("pretty geom: ${demoGeom.prettyPrint()}")
    println("latex geom: ${demoGeom.toLatex()}")
    println("string geom: ${demoGeom.toString()}")

    let bigIntCore = Core<BigInt>()
    let benchX = Variable<BigInt>("x")
    func buildDeep(n: Int64): Expression_<BigInt> {
        var expr: Expression_<BigInt> = benchX
        let one = Constant(BigInt(1))
        let two = Constant(BigInt(2))
        let x2Term = Multiply(BigInt(3), HashMap<Expression_<BigInt>, BigInt>((benchX, BigInt(2))))
        
        for (_ in 0..n) {
            expr = one + (two * expr) + x2Term
        }
        return expr
    }
/*
    println("RESULT,depth,avg_duration")
    var depth = 600
    while (depth <= 600) {
        let startFirst = MonoTime.now()
        var deepExpr = buildDeep(depth)
        deepExpr = bigIntCore.simplifyExpression(deepExpr)
        let endFirst = MonoTime.now()
        var totalDuration = endFirst - startFirst
        var i = 0
        for (_ in 0..20) {
            i += 1
            let start = MonoTime.now()
            deepExpr = buildDeep(depth)
            deepExpr = bigIntCore.simplifyExpression(deepExpr)
            let end = MonoTime.now()
            totalDuration += end - start
        }

        let averageDuration = totalDuration / i
        println("RESULT,${depth},${averageDuration}")
        depth += 5
    }
  */  
    
    let testsPassed = runRegressionTests()
    println("tests passed: ${testsPassed}")
    runPartialSumBenchmarks20()
    runTrigAndDerivativeGrowthBenchmarks()
}
