package symcalc
import std.collection.*

class FunctionRules<A> where A <: Scalar<A> & Comparable<A> & Hashable & ToString & Equatable<A> {
    var simplifyRules: HashMap<String, (ArrayList<Expression_<A>>) -> Expression_<A>> =
        HashMap<String, (ArrayList<Expression_<A>>) -> Expression_<A>>()
    var derivativeRules: HashMap<String, (ArrayList<Expression_<A>>, Expression_<A>) -> Expression_<A>> =
        HashMap<String, (ArrayList<Expression_<A>>, Expression_<A>) -> Expression_<A>>()
    var initialized: Bool = false

    func ensureDefaults() {
        if (initialized) {
            return
        }
        let trigonometricRules = TrigonometricRules<A>()
        let geometricRules = GeometricRules<A>()

        this.registerSimplifyRule("id", { args =>
            if (args.size == 1) {
                args[0]
            } else {
                Function("id", args)
            }
        })

        this.registerSimplifyRule("neg", { args =>
            if (args.size == 1) {
                Multiply(
                    A.fromInt(-1),
                    HashMap<Expression_<A>, A>((args[0], A.one()))
                ).toNormalForm()
            } else {
                Function("neg", args)
            }
        })

        this.registerSimplifyRule("sin", { args =>
            trigonometricRules.simplifySin(args)
        })

        this.registerSimplifyRule("cos", { args =>
            trigonometricRules.simplifyCos(args)
        })

        this.registerSimplifyRule("partial_sum", { args =>
            PartialSumRules<A>().simplifyPartialSum(args)
        })

        this.registerSimplifyRule("pow", { args =>
            geometricRules.simplifyPow(args)
        })

        this.registerSimplifyRule("geom_sum", { args =>
            geometricRules.simplifyGeomSum(args)
        })

        this.registerDerivativeRule("id", { args, variable =>
            if (args.size == 1) {
                args[0].derivative(variable)
            } else {
                Add(A.zero(), HashMap<Expression_<A>, A>())
            }
        })

        this.registerDerivativeRule("neg", { args, variable =>
            if (args.size == 1) {
                Multiply(
                    A.fromInt(-1),
                    HashMap<Expression_<A>, A>((args[0].derivative(variable), A.one()))
                ).toNormalForm()
            } else {
                Add(A.zero(), HashMap<Expression_<A>, A>())
            }
        })

        this.registerDerivativeRule("sin", { args, variable =>
            trigonometricRules.derivativeSin(args, variable)
        })

        this.registerDerivativeRule("cos", { args, variable =>
            trigonometricRules.derivativeCos(args, variable)
        })

        this.registerDerivativeRule("exp", { args, variable =>
            if (args.size == 1) {
                let u = args[0]
                let du = u.derivative(variable)
                (Function("exp", ArrayList<Expression_<A>>([u])) * du).toNormalForm()
            } else {
                Add(A.zero(), HashMap<Expression_<A>, A>())
            }
        })

        this.registerDerivativeRule("ln", { args, variable =>
            if (args.size == 1) {
                let u = args[0]
                let du = u.derivative(variable)
                (
                    Multiply(
                        A.one(),
                        HashMap<Expression_<A>, A>((u, A.fromInt(-1)))
                    ) * du
                ).toNormalForm()
            } else {
                Add(A.zero(), HashMap<Expression_<A>, A>())
            }
        })

        initialized = true
    }

    func simplifyRegistry():
        HashMap<String, (ArrayList<Expression_<A>>) -> Expression_<A>> {
        this.ensureDefaults()
        simplifyRules
    }

    func derivativeRegistry():
        HashMap<String, (ArrayList<Expression_<A>>, Expression_<A>) -> Expression_<A>> {
        this.ensureDefaults()
        derivativeRules
    }

    func registerSimplifyRule(
        functionName: String,
        rule: (ArrayList<Expression_<A>>) -> Expression_<A>
    ) {
        simplifyRules.add(functionName, rule)
    }

    func registerDerivativeRule(
        functionName: String,
        rule: (ArrayList<Expression_<A>>, Expression_<A>) -> Expression_<A>
    ) {
        derivativeRules.add(functionName, rule)
    }

    func buildFunction(
        functionName: String,
        args: ArrayList<Expression_<A>>
    ): Expression_<A> {
        let registry = this.simplifyRegistry()
        match (registry.get(functionName)) {
            case Some(rule) => rule(args)
            case None => Function(functionName, args)
        }
    }

    func derivativeFunction(
        functionName: String,
        args: ArrayList<Expression_<A>>,
        variable: Expression_<A>
    ): Expression_<A> {
        let registry = this.derivativeRegistry()
        match (registry.get(functionName)) {
            case Some(rule) => rule(args, variable)
            case None =>
                if (args.size == 1) {
                    let u = args[0]
                    (Function(functionName + "'", ArrayList<Expression_<A>>([u])) * u.derivative(variable))
                        .toNormalForm()
                } else {
                    Function(functionName + "'", args)
                }
        }
    }
}
