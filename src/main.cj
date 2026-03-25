package symcalc
import std.collection.*

main() {
    let testsPassed = runRegressionTests()
    println("tests passed: ${testsPassed}")

    let intCore = Core<Int64>()
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

    let sinConst = Function<Float64>("sin", ArrayList<Expression_<Float64>>([Constant(1.0)]))
    let cosConst = Function<Float64>("cos", ArrayList<Expression_<Float64>>([Constant(3.1415)]))
    let sinSymbolic = Function<Float64>("sin", ArrayList<Expression_<Float64>>([Variable("x")]))

    println("sin(1) expr: ${sinConst}")
    println("sin(1) simplified: ${floatCore.simplifyExpression(sinConst)}")
    println("cos(3.1415) expr: ${cosConst}")
    println("cos(3.1415) simplified: ${floatCore.simplifyExpression(cosConst)}")
    println("sin(x) simplified: ${floatCore.simplifyExpression(sinSymbolic)}")
}
