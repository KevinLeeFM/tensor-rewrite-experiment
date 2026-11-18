import EdgeSpec
set_option autoImplicit false
namespace RevisedBenchmark.EdgeUpdate

theorem verified : Case := by
  intro C A x y hx hy fill start high guard
  have length_eq : (base high x y.length fill).length = x.length + y.length := by
    cases high <;> simp [base, Nat.add_comm]
  unfold update
  rw [length_eq, guard]
  cases high <;> simp [base]

example : Case := verified
#print axioms verified
end RevisedBenchmark.EdgeUpdate
