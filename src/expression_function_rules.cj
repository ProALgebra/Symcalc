package symcalc
import std.collection.*

class FunctionRules<A> where A <: Scalar<A> & Comparable<A> & Hashable & ToString & Equatable<A> {
    var simplifyRules: HashMap<String, (ArrayList<Expression_<A>>) -> Expression_<A>> =
        HashMap<String, (ArrayList<Expression_<A>>) -> Expression_<A>>()
    var derivativeRules: HashMap<String, (ArrayList<Expression_<A>>, Expression_<A>) -> Expression_<A>> =
        HashMap<String, (ArrayList<Expression_<A>>, Expression_<A>) -> Expression_<A>>()
    var prettyPrintRules: HashMap<String, (ArrayList<String>) -> String> =
        HashMap<String, (ArrayList<String>) -> String>()
    var latexPrintRules: HashMap<String, (ArrayList<String>) -> String> =
        HashMap<String, (ArrayList<String>) -> String>()
    var initialized: Bool = false

    func joinArgs(args: ArrayList<String>): String {
        var argsString = ""
        var first = true
        for (arg in args) {
            if (!first) {
                argsString += ", "
            }
            argsString += arg
            first = false
        }
        argsString
    }

    func defaultPrettyFunction(functionName: String, args: ArrayList<String>): String {
        "${functionName}(${joinArgs(args)})"
    }

    func defaultLatexFunction(functionName: String, args: ArrayList<String>): String {
        "\\operatorname{${functionName}}\\left(${joinArgs(args)}\\right)"
    }

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

        this.registerPrettyPrintRule("id", { args =>
            if (args.size == 1) { args[0] } else { this.defaultPrettyFunction("id", args) }
        })
        this.registerPrettyPrintRule("neg", { args =>
            if (args.size == 1) { "-(${args[0]})" } else { this.defaultPrettyFunction("neg", args) }
        })
        this.registerPrettyPrintRule("pow", { args =>
            if (args.size == 2) { "${args[0]}^(${args[1]})" } else { this.defaultPrettyFunction("pow", args) }
        })
        this.registerPrettyPrintRule("sqrt", { args =>
            if (args.size == 1) { "sqrt(${args[0]})" } else { this.defaultPrettyFunction("sqrt", args) }
        })
        this.registerPrettyPrintRule("pi", { args =>
            if (args.isEmpty()) { "pi" } else { this.defaultPrettyFunction("pi", args) }
        })
        this.registerPrettyPrintRule("sin", { args => this.defaultPrettyFunction("sin", args) })
        this.registerPrettyPrintRule("cos", { args => this.defaultPrettyFunction("cos", args) })
        this.registerPrettyPrintRule("tan", { args => this.defaultPrettyFunction("tan", args) })
        this.registerPrettyPrintRule("log", { args => this.defaultPrettyFunction("log", args) })
        this.registerPrettyPrintRule("ln", { args => this.defaultPrettyFunction("ln", args) })
        this.registerPrettyPrintRule("exp", { args => this.defaultPrettyFunction("exp", args) })
        this.registerPrettyPrintRule("partial_sum", { args =>
            this.defaultPrettyFunction("partial_sum", args)
        })
        this.registerPrettyPrintRule("geom_sum", { args =>
            this.defaultPrettyFunction("geom_sum", args)
        })

        this.registerLatexPrintRule("id", { args =>
            if (args.size == 1) { args[0] } else { this.defaultLatexFunction("id", args) }
        })
        this.registerLatexPrintRule("neg", { args =>
            if (args.size == 1) { "-\\left(${args[0]}\\right)" } else { this.defaultLatexFunction("neg", args) }
        })
        this.registerLatexPrintRule("pow", { args =>
            if (args.size == 2) { "${args[0]}^{${args[1]}}" } else { this.defaultLatexFunction("pow", args) }
        })
        this.registerLatexPrintRule("sqrt", { args =>
            if (args.size == 1) { "\\sqrt{${args[0]}}" } else { this.defaultLatexFunction("sqrt", args) }
        })
        this.registerLatexPrintRule("pi", { args =>
            if (args.isEmpty()) { "\\pi" } else { this.defaultLatexFunction("pi", args) }
        })
        this.registerLatexPrintRule("sin", { args => "\\sin\\left(${joinArgs(args)}\\right)" })
        this.registerLatexPrintRule("cos", { args => "\\cos\\left(${joinArgs(args)}\\right)" })
        this.registerLatexPrintRule("tan", { args => "\\tan\\left(${joinArgs(args)}\\right)" })
        this.registerLatexPrintRule("log", { args => "\\log\\left(${joinArgs(args)}\\right)" })
        this.registerLatexPrintRule("ln", { args => "\\ln\\left(${joinArgs(args)}\\right)" })
        this.registerLatexPrintRule("exp", { args => "\\exp\\left(${joinArgs(args)}\\right)" })
        this.registerLatexPrintRule("partial_sum", { args =>
            if (args.size == 4) {
                "\\sum_{${args[1]}=${args[2]}}^{${args[3]}}\\left(${args[0]}\\right)"
            } else {
                this.defaultLatexFunction("partial_sum", args)
            }
        })
        this.registerLatexPrintRule("geom_sum", { args =>
            "\\operatorname{geom\\_sum}\\left(${joinArgs(args)}\\right)"
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

    func prettyPrintRegistry(): HashMap<String, (ArrayList<String>) -> String> {
        this.ensureDefaults()
        prettyPrintRules
    }

    func latexPrintRegistry(): HashMap<String, (ArrayList<String>) -> String> {
        this.ensureDefaults()
        latexPrintRules
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

    func registerPrettyPrintRule(
        functionName: String,
        rule: (ArrayList<String>) -> String
    ) {
        prettyPrintRules.add(functionName, rule)
    }

    func registerLatexPrintRule(
        functionName: String,
        rule: (ArrayList<String>) -> String
    ) {
        latexPrintRules.add(functionName, rule)
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

    public func renderFunctionPretty(functionName: String, args: ArrayList<String>): String {
        let registry = this.prettyPrintRegistry()
        match (registry.get(functionName)) {
            case Some(rule) => rule(args)
            case None => this.defaultPrettyFunction(functionName, args)
        }
    }

    public func renderFunctionLatex(functionName: String, args: ArrayList<String>): String {
        let registry = this.latexPrintRegistry()
        match (registry.get(functionName)) {
            case Some(rule) => rule(args)
            case None => this.defaultLatexFunction(functionName, args)
        }
    }
}
