package symcalc

public interface Scalar<T> {
    public static func eq(left: T, right: T): Bool

    public static func zero(): T
    public static func one(): T
    public static func fromInt(n: Int): T

    public static func add(left: T, right: T): T
    public static func mul(left: T, right: T): T
    public static func powInt(base: T, exp: Int): T
    
    public static func isZero(value: T): Bool {
        eq(value, zero())
    }
}



extend Int64 <: Scalar<Int64> {
    public static func eq(left: Int64, right: Int64): Bool { left == right }

    public static func zero(): Int64 { 0 }
    public static func one(): Int64 { 1 }
    public static func fromInt(n: Int): Int64 { n }

    public static func add(left: Int64, right: Int64): Int64 { left + right }
    public static func mul(left: Int64, right: Int64): Int64 { left * right }

    public static func powInt(base: Int64, exp: Int): Int64 {
        var ans: Int64 = 1
        var i = 0
        while (i < exp) {
            ans *= base
            i++
        }
        ans
    }
}

extend Float64 <: Scalar<Float64> {
    public static func eq(left: Float64, right: Float64): Bool { left == right }

    public static func zero(): Float64 { 0.0 }
    public static func one(): Float64 { 1.0 }
    public static func fromInt(n: Int): Float64 { Float64(n) }

    public static func add(left: Float64, right: Float64): Float64 { left + right }
    public static func mul(left: Float64, right: Float64): Float64 { left * right }

    public static func powInt(base: Float64, exp: Int): Float64 {
        var ans: Float64 = 1.0
        var i = 0
        while (i < exp) {
            ans *= base
            i++
        }
        ans
    }
}
