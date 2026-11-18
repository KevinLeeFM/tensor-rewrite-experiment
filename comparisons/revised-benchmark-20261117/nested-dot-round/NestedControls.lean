import NestedProof
set_option autoImplicit false
namespace RevisedBenchmark.NestedDot
example : leftCost 4 1 4 1 = 64 ∧ rightCost 4 1 4 1 = 16 ∧
    rightCost 1 4 1 4 = 64 ∧ leftCost 1 4 1 4 = 16 := by decide
example : rounded 25165827 = some 25165828 ∧ rounded 25165831 = some 25165832 := by decide
example : rounded (2^30+1) = none := by decide

/-- Same typed matrix chain, accumulated as exact naturals. -/
def exactDot (k : Nat) (a b : Nat → Nat → Nat) (i j : Nat) : Nat :=
  ((List.range k).map (fun t => a i t * b t j)).sum
example :
  let a := fun (_ _ : Nat) => 3
  let b := fun (_ t : Nat) => coeff t
  let c := fun (_ _ : Nat) => 1
  exactDot 4 (exactDot 1 a b) c 0 0 = 25165830 ∧
  exactDot 1 a (exactDot 4 b c) 0 0 = 25165830 := by decide
example : let ones := loadMat (fun _ _ => 1)
  left 1 4 ones ones ones 0 0 = some 4 ∧ right 1 4 ones ones ones 0 0 = some 4 := by decide
end RevisedBenchmark.NestedDot
