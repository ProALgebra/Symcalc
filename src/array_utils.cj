package symcalc
import std.collection.*

func concatArray<T>(left: Array<T>, right: Array<T>): Array<T> {
    let leftSize = left.size
    let rightSize = right.size
    Array<T>(leftSize + rightSize, { i =>
        if (i < leftSize) { left[i] } else { right[i - leftSize] }
    })
}
