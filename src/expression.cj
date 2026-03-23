package symcalc
import std.console.*
import std.collection.*
import std.sort.*

enum Expression_<A> where A <: Scalar<A> & Comparable<A> & Hashable & ToString & Equatable<A>{
    | Constant(A)
    | Variable(String)
    | Multiply(A, HashMap<Expression_<A>,A>)
    | Add(A, HashMap<Expression_<A>,A>)
    | Function(String,ArrayList<Expression_<A>>)

    public operator func +(that: Expression_<A>) : Expression_<A> {
        let x: Expression_<A> = this
        if(x.hashCode() == that.hashCode()){
            Add(A.zero(), HashMap<Expression_<A>,A>((this, A.fromInt(2)))).toNormalForm()
        }else{
            Add(
                A.zero(),
                HashMap<Expression_<A>,A>((this, A.one()), (that, A.one()))
            ).toNormalForm()
        }
    }
    public operator func *(that: Expression_<A>) : Expression_<A> {
        let x: Expression_<A> = this
        if(x.hashCode() == that.hashCode()){
            Multiply(A.one(), HashMap<Expression_<A>,A>((this, A.fromInt(2)))).toNormalForm()
        }else{
            Multiply(
                A.one(),
                HashMap<Expression_<A>,A>((this, A.one()), (that, A.one()))
            ).toNormalForm()
        }
    }


}

extend<A> Expression_<A> <: Equatable<Expression_<A>> where A <: Scalar<A> & Equatable<A> {
    public operator func ==(other: Expression_<A>): Bool {
        this.hashCode() == other.hashCode()
    }

    public operator func !=(other: Expression_<A>): Bool {
        !(this == other)
    }
}
