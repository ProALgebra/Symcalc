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

extend ConstructiveReal {
    public static func fromFraction(numerator: Int, denominator: Int): ConstructiveReal {
        crBuild(BigInt(numerator), BigInt(denominator))
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
