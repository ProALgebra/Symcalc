package symcalc
import std.collection.*

class Core<A> where A <: Scalar<A> & Comparable<A> & Hashable & ToString & Equatable<A> {
    var functionRules: FunctionRules<A> = FunctionRules<A>()

    public func getFunctionRules(): FunctionRules<A> {
        functionRules
    }

    public func setFunctionRules(functionRules: FunctionRules<A>) {
        this.functionRules = functionRules
    }

    public func simplifyExpression(expr: Expression_<A>): Expression_<A> {
        let maxIterations = 20
        var current = expr.toNormalForm()
        var iteration = 0

        while (iteration < maxIterations) {
            let next = this.simplifyNode(current).toNormalForm()
            if (next == current) {
                return next
            }
            current = next
            iteration += 1
        }
        current
    }

    public func derivativeExpression(
        expr: Expression_<A>,
        element: Expression_<A>
    ): Expression_<A> {
        let normalizedExpr = this.simplifyExpression(expr)
        normalizedExpr.derivativeWithRules(this.functionRules, element).toNormalForm()
    }

    public func substituteVariable(
        expr: Expression_<A>,
        variableName: String,
        replacement: Expression_<A>
    ): Expression_<A> {
        expr.substituteVariable(variableName, replacement).toNormalForm()
    }

    public func substituteVariable(
        expr: Expression_<A>,
        variable: Expression_<A>,
        replacement: Expression_<A>
    ): Expression_<A> {
        expr.substituteVariable(variable, replacement).toNormalForm()
    }

    func simplifyNode(expr: Expression_<A>): Expression_<A> {
        match (expr) {
            case Function(functionName, args) =>
                var simplifiedArgs = ArrayList<Expression_<A>>([])
                for (arg in args) {
                    simplifiedArgs.add(this.simplifyExpression(arg))
                }
                this.simplifyFunction(functionName, simplifiedArgs)
            case _ => expr
        }
    }

    func simplifyFunction(
        functionName: String,
        args: ArrayList<Expression_<A>>
    ): Expression_<A> {
        functionRules.buildFunction(functionName, args)
    }
}
