package symcalc
import std.collection.*
import std.sort.*

extend<A> Expression_<A> <: Hashable where A <: Scalar<A> & Comparable<A> & Hashable {
        func mulMod(a: Int64, b: Int64, m: Int64): Int64 {
            var result: Int64 = 0
            var x: Int64 = a % m
            var y: Int64 = b

            while(y > 0){
                if(y % 2 == 1){
                    result = (result + x) % m
                }
                x = (x * 2) % m
                y = y / 2
            }
            return result
        }

        func expressionKind(expr: Expression_<A>): Int {
            match (expr) {
                case Constant(_) => 0
                case Variable(_) => 1
                case Add(_,_) => 2
                case Multiply(_,_) => 3
                case Function(_,_) => 4
            }
        }

        func sortedEntries<V>(map: HashMap<Expression_<A>, V>): ArrayList<(Expression_<A>, V)>
            where V <: Comparable<V> {
            var entries: ArrayList<(Expression_<A>, V)> = ArrayList<(Expression_<A>, V)>([])
            for((k,v) in map){
                entries.add((k,v))
            }
            sort<(Expression_<A>, V)>(
                    entries,
                    by:{a, b => 
                        let state = compareExpression(a[0], b[0])
                        match (state) {
                            case Ordering.EQ => a[1].compare(b[1])
                            case _ => state
                        }
                    }
                )
            entries
        }

        func compareMaps<V>(
            left: HashMap<Expression_<A>, V>,
            right: HashMap<Expression_<A>, V>
        ): Ordering where V <: Comparable<V> {
            let leftEntries = sortedEntries(left)
            let rightEntries = sortedEntries(right)

            let sizeState = leftEntries.size.compare(rightEntries.size)
            match (sizeState) {
                case Ordering.EQ => ()
                case _ => return sizeState
            }

            var i: Int = 0
            while (i < leftEntries.size) {
                let leftEntry = leftEntries[i]
                let rightEntry = rightEntries[i]

                let keyState = compareExpression(leftEntry[0], rightEntry[0])
                match (keyState) {
                    case Ordering.EQ => ()
                    case _ => return keyState
                }

                let valueState = leftEntry[1].compare(rightEntry[1])
                match (valueState) {
                    case Ordering.EQ => ()
                    case _ => return valueState
                }

                i += 1
            }

            Ordering.EQ
        }

        func compareExpression(left: Expression_<A>, right: Expression_<A>): Ordering {
            let leftKind = expressionKind(left)
            let rightKind = expressionKind(right)
            let kindState = leftKind.compare(rightKind)
            match (kindState) {
                case Ordering.EQ => ()
                case _ => return kindState
            }

            match ((left, right)) {
                case (Constant(a), Constant(b)) => a.compare(b)
                case (Variable(a), Variable(b)) => a.compare(b)
                case (Add(ac1, m1), Add(ac2, m2)) =>
                    let constState = ac1.compare(ac2)
                    match (constState) {
                        case Ordering.EQ => compareMaps(m1, m2)
                        case _ => constState
                    }
                case (Multiply(ac1, m1), Multiply(ac2, m2)) =>
                    let constState = ac1.compare(ac2)
                    match (constState) {
                        case Ordering.EQ => compareMaps(m1, m2)
                        case _ => constState
                    }
                case (Function(name1, vars1), Function(name2, vars2)) =>
                    let nameState = name1.compare(name2)
                    match (nameState) {
                        case Ordering.EQ =>
                            let sizeState = vars1.size.compare(vars2.size)
                            match (sizeState) {
                                case Ordering.EQ => ()
                                case _ => return sizeState
                            }
                            var i: Int = 0
                            while (i < vars1.size) {
                                let argState = compareExpression(vars1[i], vars2[i])
                                match (argState) {
                                    case Ordering.EQ => ()
                                    case _ => return argState
                                }
                                i += 1
                            }
                            Ordering.EQ
                        case _ => nameState
                    }
                case _ => Ordering.EQ
            }
        }

        func createHashFromMap<V>(map: HashMap<Expression_<A>, V>): Int64
            where V <: Hashable & Comparable<V> {
            let arrayMap = sortedEntries(map)
            var ans: Int64 = 0
            for((k,v) in arrayMap){
                ans = mulMod(ans, 31, 618970019642690137)
                ans = ans % 618970019642690137  
                ans += k.hashCode()
                ans = ans % 618970019642690137  
                ans = mulMod(ans, 31, 618970019642690137)
                ans = ans % 618970019642690137  
                ans += v.hashCode()
                ans = ans % 618970019642690137  
            }

            ans
        }

        func createHashFromVars(vars: ArrayList<Expression_<A>>): Int64 {
            var ans: Int64 = 0
            for(v in vars){
                ans = mulMod(ans, 31, 618970019642690137)
                ans = ans % 618970019642690137
                ans += v.hashCode()
                ans = ans % 618970019642690137
            }
            ans
        }

        public func hashCode(): Int64 {
            match (this) {
                case Constant(n) => 1 * 31 + n.hashCode()
                case Variable(a) => 2 * 31 + a.hashCode()
                case Add(ac, avars) => 
                    var hash:Int64 = 3
                    hash = 
                        mulMod(hash, 31, 618970019642690137) + ac.hashCode()
                    hash = hash % 618970019642690137  
                    hash = 
                        mulMod(hash, 31, 618970019642690137) + createHashFromMap(avars)
                    hash = hash % 618970019642690137  
                    hash
                case Multiply(ac, avars) => 
                    var hash:Int64 = 4
                    hash = 
                        mulMod(hash, 31, 618970019642690137) + ac.hashCode()
                    hash = hash % 618970019642690137  
                    hash = 
                        mulMod(hash, 31, 618970019642690137) + createHashFromMap(avars)
                    hash = hash % 618970019642690137  
                    hash
                case Function(ac, avars) => 
                    var hash:Int64 = 5
                    hash = 
                        mulMod(hash, 31, 618970019642690137) + ac.hashCode()
                    hash = hash % 618970019642690137  
                    hash = 
                        mulMod(hash, 31, 618970019642690137) + createHashFromVars(avars)
                    hash = hash % 618970019642690137  
                    hash
            }
    }
}
