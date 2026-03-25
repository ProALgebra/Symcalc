package symcalc
import std.collection.*
import std.math.numeric.BigInt
import std.time.*

main() {
    let testsPassed = runRegressionTests()
    println("tests passed: ${testsPassed}")

    let intCore = Core<Int64>()
    let bigIntCore = Core<BigInt>()
    let floatCore = Core<Float64>()

    let iterator = Variable<Int64>("i")
    let partialSumExpr = Function<Int64>(
        "partial_sum",
        ArrayList<Expression_<Int64>>([
            Add(2, HashMap<Expression_<Int64>, Int64>((iterator, 1),)),
            iterator,
            Constant(1),
            Constant(4)
        ])
    )
    println("partial_sum expr: ${partialSumExpr}")
    println("partial_sum simplified: ${intCore.simplifyExpression(partialSumExpr)}")

    let geometricViaPartial = Function<Float64>(
        "partial_sum",
        ArrayList<Expression_<Float64>>([
            Multiply(
                2.0,
                HashMap<Expression_<Float64>, Float64>((
                    Function(
                        "pow",
                        ArrayList<Expression_<Float64>>([Constant(3.0), Variable<Float64>("i")])
                    ),
                    1.0
                ),)
            ),
            Variable<Float64>("i"),
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
    println("geom via partial_sum: ${floatCore.simplifyExpression(geometricViaPartial)}")
    println("geom via geom_sum: ${floatCore.simplifyExpression(geometricDirect)}")

    let sinConst = Function<Float64>("sin", ArrayList<Expression_<Float64>>([Constant(1.25)]))
    let cosConst = Function<Float64>("cos", ArrayList<Expression_<Float64>>([Constant(3.1415)]))
    let sinSymbolic = Function<Float64>("sin", ArrayList<Expression_<Float64>>([Variable("x")]))
    let trigX = Variable<Float64>("x")
    let xSquared = Multiply(
        1.0,
        HashMap<Expression_<Float64>, Float64>((trigX, 2.0),)
    )
    let sinComposite = Function<Float64>(
        "sin",
        ArrayList<Expression_<Float64>>([
            Add(
                1.0,
                HashMap<Expression_<Float64>, Float64>((xSquared, 1.0),)
            )
        ])
    )
    let sinCompositeDerivativeStart = MonoTime.now()
    let sinCompositeDerivative = floatCore.derivativeExpression(sinComposite, trigX)
    let sinCompositeDerivativeEnd = MonoTime.now()
    let sinCompositeEvaluateStart = MonoTime.now()
    let sinCompositeAtHalf = floatCore.simplifyExpression(
        floatCore.substituteVariable(sinComposite, "x", Constant(0.5))
    )
    let sinCompositeEvaluateEnd = MonoTime.now()

    println("sin(1) expr: ${sinConst}")
    println("sin(1) simplified: ${floatCore.simplifyExpression(sinConst)}")
    println("cos(3.1415) expr: ${cosConst}")
    println("cos(3.1415) simplified: ${floatCore.simplifyExpression(cosConst)}")
    println("sin(x) simplified: ${floatCore.simplifyExpression(sinSymbolic)}")
    println("sin(x^2 + 1) expr: ${sinComposite}")
    println("d/dx sin(x^2 + 1): ${sinCompositeDerivative}")
    println("time d/dx sin(x^2 + 1): ${sinCompositeDerivativeEnd - sinCompositeDerivativeStart}")
    println("sin(x^2 + 1) at x=0.5: ${sinCompositeAtHalf}")
    println("time evaluate sin(x^2 + 1) at x=0.5: ${sinCompositeEvaluateEnd - sinCompositeEvaluateStart}")

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

    let start = MonoTime.now()
    var deepExpr = buildDeep(10)
    deepExpr = bigIntCore.simplifyExpression(deepExpr)
    let end = MonoTime.now()
    let duration = end - start
    println("deep simplify result: ${deepExpr}")
    println("time test duration: ${duration}")

    let bigInt1 = BigInt(-3)
    let bitLen1 = bigInt1.bitLen
    println(bitLen1)

    let bigInt2 = BigInt(-1)
    let bitLen2 = bigInt2.bitLen
    println(bitLen2)

    let bigInt3 = BigInt(0)
    let bitLen3 = bigInt3.bitLen
    println(bitLen3)

    let huge = BigInt.powInt(BigInt(2), 1000) - BigInt(1)
    let addStart = MonoTime.now()
    let hugeSum = huge + huge
    let addEnd = MonoTime.now()
    println(hugeSum)
    println("bigint add time: ${addEnd - addStart}")
}
