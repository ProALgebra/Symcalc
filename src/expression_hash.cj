package symcalc
import std.collection.*
import std.sort.*

extend<A> Expression_<A> <: Hashable where A <: Scalar<A> & Comparable<A> & Hashable {
        func hashModulus(): Int64 {
            618970019642690137
        }

        func normalizeMod(value: Int64, m: Int64): Int64 {
            var v = value % m
            if (v < 0) {
                v += m
            }
            v
        }

        func addMod(a: Int64, b: Int64, m: Int64): Int64 {
            let x = normalizeMod(a, m)
            let y = normalizeMod(b, m)
            if (x >= m - y) {
                x - (m - y)
            } else {
                x + y
            }
        }

        func mulMod31(a: Int64, m: Int64): Int64 {
            let a2 = addMod(a, a, m)
            let a4 = addMod(a2, a2, m)
            let a8 = addMod(a4, a4, m)
            let a16 = addMod(a8, a8, m)
            addMod(addMod(addMod(addMod(a16, a8, m), a4, m), a2, m), a, m)
        }

        func mulMod131(a: Int64, m: Int64): Int64 {
            let a2 = addMod(a, a, m)
            let a4 = addMod(a2, a2, m)
            let a8 = addMod(a4, a4, m)
            let a16 = addMod(a8, a8, m)
            let a32 = addMod(a16, a16, m)
            let a64 = addMod(a32, a32, m)
            let a128 = addMod(a64, a64, m)
            addMod(addMod(a128, a2, m), a, m)
        }

        func mulMod137(a: Int64, m: Int64): Int64 {
            let a2 = addMod(a, a, m)
            let a4 = addMod(a2, a2, m)
            let a8 = addMod(a4, a4, m)
            let a16 = addMod(a8, a8, m)
            let a32 = addMod(a16, a16, m)
            let a64 = addMod(a32, a32, m)
            let a128 = addMod(a64, a64, m)
            addMod(addMod(a128, a8, m), a, m)
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
        ): Ordering where V <: Hashable {
            let sizeState = left.size.compare(right.size)
            match (sizeState) {
                case Ordering.EQ => ()
                case _ => return sizeState
            }
            createHashFromMap(left).compare(createHashFromMap(right))
        }

        func compareExpression(left: Expression_<A>, right: Expression_<A>): Ordering {
            left.hashCode().compare(right.hashCode())
        }

        func mapEntryHash<V>(key: Expression_<A>, value: V): Int64 where V <: Hashable {
            let m = hashModulus()
            var ans: Int64 = 17
            let keyHash = key.hashCode()
            let valueHash = value.hashCode()
            ans = addMod(mulMod131(ans, m), keyHash, m)
            ans = addMod(mulMod137(ans, m), valueHash, m)
            ans
        }

        // Order-independent map hash for commutative expression terms.
        func createHashFromMap<V>(map: HashMap<Expression_<A>, V>): Int64 where V <: Hashable {
            let m = hashModulus()
            var sumHashes: Int64 = 0
            var xorHashes: Int64 = 0
            var weightedSum: Int64 = 0
            var count: Int64 = 0

            for ((k, v) in map) {
                let entryHash = mapEntryHash(k, v)
                sumHashes = addMod(sumHashes, entryHash, m)
                xorHashes = xorHashes ^ entryHash
                weightedSum = addMod(weightedSum, mulMod31(entryHash, m), m)
                count += 1
            }

            var ans: Int64 = 0
            ans = addMod(ans, sumHashes, m)
            ans = addMod(mulMod31(ans, m), normalizeMod(xorHashes, m), m)
            ans = addMod(mulMod31(ans, m), weightedSum, m)
            ans = addMod(mulMod31(ans, m), count, m)
            ans
        }

        func createHashFromVars(vars: ArrayList<Expression_<A>>): Int64 {
            let m = hashModulus()
            var ans: Int64 = 0
            for(v in vars){
                ans = mulMod31(ans, m)
                ans = addMod(ans, v.hashCode(), m)
            }
            ans
        }

        public func hashCode(): Int64 {
            match (this) {
                case Constant(n) =>
                    addMod(mulMod31(1, hashModulus()), n.hashCode(), hashModulus())
                case Variable(a) =>
                    addMod(mulMod31(2, hashModulus()), a.hashCode(), hashModulus())
                case Add(ac, avars) => 
                    var hash:Int64 = 3
                    hash = addMod(
                        mulMod31(hash, hashModulus()),
                        ac.hashCode(),
                        hashModulus()
                    )
                    hash = addMod(
                        mulMod31(hash, hashModulus()),
                        createHashFromMap(avars),
                        hashModulus()
                    )
                    hash
                case Multiply(ac, avars) => 
                    var hash:Int64 = 4
                    hash = addMod(
                        mulMod31(hash, hashModulus()),
                        ac.hashCode(),
                        hashModulus()
                    )
                    hash = addMod(
                        mulMod31(hash, hashModulus()),
                        createHashFromMap(avars),
                        hashModulus()
                    )
                    hash
                case Function(ac, avars) => 
                    var hash:Int64 = 5
                    hash = addMod(
                        mulMod31(hash, hashModulus()),
                        ac.hashCode(),
                        hashModulus()
                    )
                    hash = addMod(
                        mulMod31(hash, hashModulus()),
                        createHashFromVars(avars),
                        hashModulus()
                    )
                    hash
            }
    }
}
