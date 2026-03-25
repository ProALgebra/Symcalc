package symcalc
import std.collection.*

class TrigonometricRules<A> where A <: Scalar<A> & Comparable<A> & Hashable & ToString & Equatable<A> {
    func factorialAsScalar(n: Int): A {
        var result = A.one()
        var i = 2
        while (i <= n) {
            result = A.mul(result, A.fromInt(i))
            i += 1
        }
        result
    }

    func taylorSin(x: A, terms: Int): A {
        var sum = A.zero()
        var k = 0
        while (k < terms) {
            let power = A.powInt(x, 2 * k + 1)
            let factorial = this.factorialAsScalar(2 * k + 1)
            var term = A.div(power, factorial)
            if (k % 2 == 1) {
                term = A.mul(A.fromInt(-1), term)
            }
            sum = A.add(sum, term)
            k += 1
        }
        sum
    }

    func taylorCos(x: A, terms: Int): A {
        var sum = A.zero()
        var k = 0
        while (k < terms) {
            let power = A.powInt(x, 2 * k)
            let factorial = this.factorialAsScalar(2 * k)
            var term = A.div(power, factorial)
            if (k % 2 == 1) {
                term = A.mul(A.fromInt(-1), term)
            }
            sum = A.add(sum, term)
            k += 1
        }
        sum
    }

    public func simplifySin(args: ArrayList<Expression_<A>>): Expression_<A> {
        if (args.size == 1) {
            let x = args[0].toNormalForm()
            match (x) {
                case Constant(value) => Constant(this.taylorSin(value, 12))
                case _ => Function("sin", ArrayList<Expression_<A>>([x]))
            }
        } else {
            Function("sin", args)
        }
    }

    public func simplifyCos(args: ArrayList<Expression_<A>>): Expression_<A> {
        if (args.size == 1) {
            let x = args[0].toNormalForm()
            match (x) {
                case Constant(value) => Constant(this.taylorCos(value, 12))
                case _ => Function("cos", ArrayList<Expression_<A>>([x]))
            }
        } else {
            Function("cos", args)
        }
    }

    public func derivativeSin(
        args: ArrayList<Expression_<A>>,
        variable: Expression_<A>
    ): Expression_<A> {
        if (args.size == 1) {
            let u = args[0]
            let du = u.derivative(variable)
            (Function("cos", ArrayList<Expression_<A>>([u])) * du).toNormalForm()
        } else {
            Add(A.zero(), HashMap<Expression_<A>, A>())
        }
    }

    public func derivativeCos(
        args: ArrayList<Expression_<A>>,
        variable: Expression_<A>
    ): Expression_<A> {
        if (args.size == 1) {
            let u = args[0]
            let du = u.derivative(variable)
            (
                Multiply(
                    A.fromInt(-1),
                    HashMap<Expression_<A>, A>((Function("sin", ArrayList<Expression_<A>>([u])), A.one()))
                ) * du
            ).toNormalForm()
        } else {
            Add(A.zero(), HashMap<Expression_<A>, A>())
        }
    }
}
