import ArgReuseSpec
set_option autoImplicit false
namespace RevisedBenchmark.ArgWord
open RevisedBenchmark.ArgReuse
def step {n w : Nat} (d : Direction) (a b : Value n × BitVec w) : Value n × BitVec w :=
  let left := preferLeft d a.1 b.1
  (if left then a.1 else b.1, if left || (numericEq a.1 b.1 && decide (a.2.toInt < b.2.toInt))
    then a.2 else b.2)
def reduce {n : Nat} (w len : Nat) (d : Direction) (v : Value n) : Value n × BitVec w :=
  (List.range len).foldl (fun a i => step d a (v, BitVec.ofNat w i)) (seed n d, 0)
def Case (d : Direction) : Prop := ∀ (n w len : Nat) (_ : 0 < w) (_ : 1 < len) (v : Value n),
  reduce w len d v = (v, 0)
end RevisedBenchmark.ArgWord
