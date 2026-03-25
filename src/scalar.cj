package symcalc
import std.math.numeric.BigInt

public interface Scalar<T> {
    public static func eq(left: T, right: T): Bool

    public static func zero(): T
    public static func one(): T
    public static func fromInt(n: Int): T

    public static func add(left: T, right: T): T
    public static func mul(left: T, right: T): T
    public static func div(left: T, right: T): T
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
    public static func div(left: Int64, right: Int64): Int64 { left / right }

    public static func powInt(base: Int64, exp: Int): Int64 {
        if (exp <= 0) {
            return 1
        }
        var result: Int64 = 1
        var currentBase = base
        var currentExp = exp
        while (currentExp > 0) {
            if (currentExp % 2 == 1) {
                result *= currentBase
            }
            currentBase *= currentBase
            currentExp /= 2
        }
        result
    }
}

extend Float64 <: Scalar<Float64> {
    public static func eq(left: Float64, right: Float64): Bool { left == right }

    public static func zero(): Float64 { 0.0 }
    public static func one(): Float64 { 1.0 }
    public static func fromInt(n: Int): Float64 { Float64(n) }

    public static func add(left: Float64, right: Float64): Float64 { left + right }
    public static func mul(left: Float64, right: Float64): Float64 { left * right }
    public static func div(left: Float64, right: Float64): Float64 { left / right }

    public static func powInt(base: Float64, exp: Int): Float64 {
        if (exp <= 0) {
            return 1.0
        }
        var result: Float64 = 1.0
        var currentBase = base
        var currentExp = exp
        while (currentExp > 0) {
            if (currentExp % 2 == 1) {
                result *= currentBase
            }
            currentBase *= currentBase
            currentExp /= 2
        }
        result
    }
}

extend BigInt <: Scalar<BigInt> {
    public static func eq(left: BigInt, right: BigInt): Bool { left == right }

    public static func zero(): BigInt { BigInt(0) }
    public static func one(): BigInt { BigInt(1) }
    public static func fromInt(n: Int): BigInt { BigInt(n) }

    public static func add(left: BigInt, right: BigInt): BigInt { left + right }
    public static func mul(left: BigInt, right: BigInt): BigInt { left * right }
    public static func div(left: BigInt, right: BigInt): BigInt { left / right }

    public static func powInt(base: BigInt, exp: Int): BigInt {
        if (exp <= 0) {
            return BigInt(1)
        }
        var result = BigInt(1)
        var currentBase = base
        var currentExp = exp
        while (currentExp > 0) {
            if (currentExp % 2 == 1) {
                result *= currentBase
            }
            currentBase *= currentBase
            currentExp /= 2
        }
        result
    }
}
