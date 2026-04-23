package symcalc
import std.math.numeric.BigInt

public enum ConstructiveReal {
    | CR(BigInt, BigInt)
}

func crAbs(value: BigInt): BigInt {
    if (value < BigInt(0)) {
        BigInt(0) - value
    } else {
        value
    }
}

func crGcd(left: BigInt, right: BigInt): BigInt {
    var a = crAbs(left)
    var b = crAbs(right)
    while (b != BigInt(0)) {
        let remainder = a % b
        a = b
        b = remainder
    }
    if (a == BigInt(0)) {
        BigInt(1)
    } else {
        a
    }
}

func crNormalize(numerator: BigInt, denominator: BigInt): (BigInt, BigInt) {
    var n = numerator
    var d = denominator
    if (d < BigInt(0)) {
        n = BigInt(0) - n
        d = BigInt(0) - d
    }
    let gcd = crGcd(n, d)
    (n / gcd, d / gcd)
}

func crBuild(numerator: BigInt, denominator: BigInt): ConstructiveReal {
    let (n, d) = crNormalize(numerator, denominator)
    ConstructiveReal.CR(n, d)
}

func crPow2(bits: Int): BigInt {
    if (bits <= 0) {
        BigInt(1)
    } else {
        BigInt.powInt(BigInt(2), bits)
    }
}

func crFloorDiv(numerator: BigInt, denominator: BigInt): BigInt {
    var q = numerator / denominator
    let r = numerator % denominator
    if (r != BigInt(0) && numerator < BigInt(0)) {
        q -= BigInt(1)
    }
    q
}

func crCeilDiv(numerator: BigInt, denominator: BigInt): BigInt {
    var q = numerator / denominator
    let r = numerator % denominator
    if (r != BigInt(0) && numerator > BigInt(0)) {
        q += BigInt(1)
    }
    q
}

extend ConstructiveReal {
    public static func fromFraction(numerator: Int, denominator: Int): ConstructiveReal {
        crBuild(BigInt(numerator), BigInt(denominator))
    }

    public static func fromBigIntFraction(
        numerator: BigInt,
        denominator: BigInt
    ): ConstructiveReal {
        crBuild(numerator, denominator)
    }

    public func approximateDyadic(bits: Int): (BigInt, BigInt) {
        match (this) {
            case ConstructiveReal.CR(numerator, denominator) =>
                let scale = crPow2(bits)
                let scaled = numerator * scale
                let low = crFloorDiv(scaled, denominator)
                let high = crCeilDiv(scaled, denominator)
                (low, high)
        }
    }

    public func toDecimalString(fractionDigits: Int): String {
        match (this) {
            case ConstructiveReal.CR(numerator, denominator) =>
                let isNegative = numerator < BigInt(0)
                let absNumerator = crAbs(numerator)
                let integerPart = absNumerator / denominator
                var remainder = absNumerator % denominator

                var fractionalPart = ""
                var i = 0
                while (i < fractionDigits) {
                    remainder *= BigInt(10)
                    let digit = remainder / denominator
                    remainder %= denominator
                    fractionalPart += "${digit}"
                    i += 1
                }

                let sign = if (isNegative) { "-" } else { "" }
                if (fractionDigits <= 0) {
                    return "${sign}${integerPart}"
                }
                "${sign}${integerPart}.${fractionalPart}"
        }
    }
}

extend ConstructiveReal <: ToString {
    public func toString(): String {
        match (this) {
            case ConstructiveReal.CR(numerator, denominator) =>
                if (denominator == BigInt(1)) {
                    "${numerator}"
                } else {
                    "${numerator}/${denominator}"
                }
        }
    }
}

extend ConstructiveReal <: Comparable<ConstructiveReal> {
    public func compare(other: ConstructiveReal): Ordering {
        match (this) {
            case ConstructiveReal.CR(leftNumerator, leftDenominator) =>
                match (other) {
                    case ConstructiveReal.CR(rightNumerator, rightDenominator) =>
                        let leftScaled = leftNumerator * rightDenominator
                        let rightScaled = rightNumerator * leftDenominator
                        leftScaled.compare(rightScaled)
                }
        }
    }
}

extend ConstructiveReal <: Equatable<ConstructiveReal> {
    public operator func ==(other: ConstructiveReal): Bool {
        this.compare(other) == Ordering.EQ
    }

    public operator func !=(other: ConstructiveReal): Bool {
        !(this == other)
    }
}

extend ConstructiveReal <: Hashable {
    public func hashCode(): Int64 {
        match (this) {
            case ConstructiveReal.CR(numerator, denominator) =>
                numerator.hashCode() * 37 + denominator.hashCode()
        }
    }
}

extend ConstructiveReal <: Scalar<ConstructiveReal> {
    public static func eq(left: ConstructiveReal, right: ConstructiveReal): Bool {
        left == right
    }

    public static func zero(): ConstructiveReal {
        crBuild(BigInt(0), BigInt(1))
    }

    public static func one(): ConstructiveReal {
        crBuild(BigInt(1), BigInt(1))
    }

    public static func fromInt(n: Int): ConstructiveReal {
        crBuild(BigInt(n), BigInt(1))
    }

    public static func add(left: ConstructiveReal, right: ConstructiveReal): ConstructiveReal {
        match (left) {
            case ConstructiveReal.CR(leftNumerator, leftDenominator) =>
                match (right) {
                    case ConstructiveReal.CR(rightNumerator, rightDenominator) =>
                        crBuild(
                            leftNumerator * rightDenominator + rightNumerator * leftDenominator,
                            leftDenominator * rightDenominator
                        )
                }
        }
    }

    public static func mul(left: ConstructiveReal, right: ConstructiveReal): ConstructiveReal {
        match (left) {
            case ConstructiveReal.CR(leftNumerator, leftDenominator) =>
                match (right) {
                    case ConstructiveReal.CR(rightNumerator, rightDenominator) =>
                        crBuild(leftNumerator * rightNumerator, leftDenominator * rightDenominator)
                }
        }
    }

    public static func div(left: ConstructiveReal, right: ConstructiveReal): ConstructiveReal {
        match (left) {
            case ConstructiveReal.CR(leftNumerator, leftDenominator) =>
                match (right) {
                    case ConstructiveReal.CR(rightNumerator, rightDenominator) =>
                        crBuild(leftNumerator * rightDenominator, leftDenominator * rightNumerator)
                }
        }
    }

    public static func powInt(base: ConstructiveReal, exp: Int): ConstructiveReal {
        if (exp <= 0) {
            return one()
        }
        match (base) {
            case ConstructiveReal.CR(numerator, denominator) =>
                crBuild(BigInt.powInt(numerator, exp), BigInt.powInt(denominator, exp))
        }
    }
}
