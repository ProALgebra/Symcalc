package symcalc
import std.collection.*




enum Expression_2<A> where A <: Scalar<A> & Comparable<A> & Hashable & ToString & Equatable<A>{
    | Constant(A)
    | Variable(String)
    | Multiply(A, HashMap<Expression_2<A>,A>)
    | Add(A, HashMap<Expression_2<A>,A>)
}
extend<A> Expression_2<A> <: Hashable where A <: Scalar<A> & Comparable<A> & Hashable {

        public func hashCode(): Int64 {
            2
            
    }
}
extend<A> Expression_2<A> <: Equatable<Expression_2<A>> where A <: Scalar<A> & Equatable<A> {
    public operator func ==(other: Expression_2<A>): Bool {
        match ((this, other)) {
            case (Constant(a), Constant(b)) => A.eq(a, b)
            case (Variable(a), Variable(b)) => a == b
            case (Add(ac1, m1), Add(ac2, m2)) =>
                A.eq(ac1, ac2) && m1 == m2
            case (Multiply(ac1, m1), Multiply(ac2, m2)) =>
                A.eq(ac1, ac2) && m1 == m2
            case _ => false
        }
    }

    public operator func !=(other: Expression_2<A>): Bool {
        !(this == other)
    }
}
main() {
    var x = HashMap<Expression_2<Int>, Int>((Variable("x"),2),(Multiply(1,HashMap<Expression_2<Int>, Int>((Variable("x"),2))),2))
    print(x.get(Multiply(1,HashMap<Expression_2<Int>, Int>((Variable("x"),2)))))
   /*println(11 % 10)
    let x = (Add(1,HashMap<Expression_<Int>,Int>((Multiply(1, HashMap<Expression_<Int>,Int>((Variable("x"),2))), 1),(Multiply(2, HashMap<Expression_<Int>,Int>()), 1))))
    let y = (Add(1,HashMap<Expression_<Int>,Int>((Multiply(2, HashMap<Expression_<Int>,Int>()), 1),(Multiply(1, HashMap<Expression_<Int>,Int>((Variable("x"),3))), 1))))
    println(x.toString())
    println(x.hashCode())
    println(y.toString())
    println(y.hashCode())
    let z = HashMap<Expression_<Int>,Int>((Variable("x"),2))
    z.add(Variable("x"),3)
    println(z.toString())

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
    //println(expression.toNormalForm().toString())
    //println(expression.hashCode())
    var expression2 = expression
        // expression + expression.toNormalForm() + Add(0,HashMap<Expression_<Int>,Int>((Variable("x"),3)))+ Constant(1) + Variable("x") + Variable("x") + Multiply(1, HashMap<Expression_<Int>,Int>()) + Multiply(1, HashMap<Expression_<Int>,Int>())
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
    println(expression2.toNormalForm().derivative(Variable("x")))
    
    let start = MonoTime.now()
    expression2 = buildDeep(61)
    println(expression2.derivative(Variable("x")).toNormalForm())
    let end = MonoTime.now()
    let duration = end - start
    println("Time (ms): ${duration}")
    
 */


}
