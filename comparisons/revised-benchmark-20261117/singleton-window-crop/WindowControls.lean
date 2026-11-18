module
import WindowProof
set_option autoImplicit false
namespace RevisedBenchmark.SingletonWindow
example : Goal := verified
private def one (a : Axis) : Fin 1 → Axis := fun _ => a
private def read1 (i : Fin 1 → Int) := 100+i 0
private def mixed := one ⟨5,-2,3⟩
example : start (mixed 0) = 2 ∧ stop (mixed 0) = 5 ∧ output (mixed 0) = 6 := by decide
example : old mixed (fun _ => 0) .add 0 read1 = 102 ∧
    emitted mixed (fun _ => 3) .add 0 read1 = 0 := by decide
example : old mixed (fun _ => 2) .minimum 103 read1 = 103 ∧
    emitted mixed (fun _ => 2) .maximum 103 read1 = 104 := by decide
example : emitted mixed (fun _ => 0) .add 0 read1 ≠ read1 (fun _ => 0) := by decide
example : full (one ⟨3,-3,5⟩) ∧ full (one ⟨3,5,-4⟩) := by decide
example : output ⟨3,-3,5⟩ = 5 ∧ old (one ⟨3,-3,5⟩) (fun _ => 2) .maximum 7 read1 = 7 := by decide
example : output ⟨3,-2,-2⟩ = 0 := by decide
private def two : Fin 2 → Axis := fun i => if i = 0 then ⟨4,1,-1⟩ else ⟨2,-2,3⟩
example : full two ∧ emitted two (fun _ => 1) .minimum 4 (fun _ => 0) = 4 := by decide
example : old (one ⟨2,1,0⟩) (fun _ => 0) .add 0 read1 = 0 ∧
    emitted (one ⟨2,0,0⟩) (fun _ => 1) .add 0 read1 = 101 := by decide
end RevisedBenchmark.SingletonWindow
