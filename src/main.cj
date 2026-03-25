package symcalc
import std.collection.*
import std.time.*



main() {
    let core = Core<Int>()
   /*println(11 % 10)
    let x = (Add(1,HashMap<Expression_<Int>,Int>((Multiply(1, HashMap<Expression_<Int>,Int>((Variable("x"),2))), 1),(Multiply(2, HashMap<Expression_<Int>,Int>()), 1))))
    let y = (Add(1,HashMap<Expression_<Int>,Int>((Multiply(2, HashMap<Expression_<Int>,Int>()), 1),(Multiply(1, HashMap<Expression_<Int>,Int>((Variable("x"),3))), 1))))
    println(x.toString())
    println(x.hashCode())
    println(y.toString())
    println(y.hashCode())
    let z = HashMap<Expression_<Int>,Int>((Variable("x"),2))
    z.add(Variable("x"),3)
    println(z.toString())*/
    let expression = (
        Add(1,
            HashMap<Expression_<Int>,Int>(
                (Multiply(1, HashMap<Expression_<Int>,Int>()), 1),
                (Multiply(2, HashMap<Expression_<Int>,Int>((Variable("x"),3))), 1),
                (Add(2, HashMap<Expression_<Int>,Int>(
                    (Variable("x"),3),
                    (Add(2, HashMap<Expression_<Int>,Int>((Variable("x"),3))), 2)
                    
                    )), 1)
            )
            
        )
    )
    //println(core.simplifyExpression(expression).toString())
    //println(expression.hashCode())
    var expression2 = expression
        // expression + core.simplifyExpression(expression) + Add(0,HashMap<Expression_<Int>,Int>((Variable("x"),3)))+ Constant(1) + Variable("x") + Variable("x") + Multiply(1, HashMap<Expression_<Int>,Int>()) + Multiply(1, HashMap<Expression_<Int>,Int>())
    //)
    expression2 =
        Variable<Int>("y") +
        Multiply(2, HashMap<Expression_<Int>,Int>((Multiply(1,HashMap<Expression_<Int>,Int>((Variable("x"),2))),1),))
    let x = Variable<Int>("x")

    func buildDeep(n: Int): Expression_<Int> {
        var expr: Expression_<Int> = x

        for(i in 0..n) {
            expr = Add(1, HashMap<Expression_<Int>,Int>(
                (expr, 2),
                (Multiply(1, HashMap<Expression_<Int>,Int>((x,2))), 3)
            ))
        }

        return expr
    }
    println(core.derivativeExpression(expression2, Variable("x")))
    
    let start = MonoTime.now()
    expression2 = buildDeep(61)
    expression2 = core.simplifyExpression(expression2)
    let end = MonoTime.now()
    println(expression2)
    let duration = end - start
    println("Time (ms): ${duration}")
    
 


}
