import LookupSpec
set_option autoImplicit false
namespace RevisedBenchmark.DotLookup
open TensorRewrite.Pilot.DynamicIndex
private theorem full {n : Nat} (s : Int) (i : Fin n) : atSlice (Nat.le_refl n) s i = i := by
  apply Fin.ext
  simp [atSlice,clampStart,Int.min_eq_right (Int.le_max_left 0 s)]

theorem verified : Case := by
  intro m n k hm side cf s0 s1 x y
  funext u j
  cases side <;> simp [orig,repl,full]
example : Case := verified
#print axioms verified
end RevisedBenchmark.DotLookup
