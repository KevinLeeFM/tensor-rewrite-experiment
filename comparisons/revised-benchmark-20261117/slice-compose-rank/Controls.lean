module
public import Proof
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.SliceComposeRank
open TensorRewrite.Pilot TensorRewrite.Pilot.SliceShape TensorRewrite.Pilot.IndexMaps

/-- The rank-zero case has an inhabited scalar index. -/
example : Nonempty (Index (fun i : Fin 0 => nomatch i)) := ⟨fun i => nomatch i⟩
example : Goal := correctness
/-- A zero extent excludes every coordinate, so pointwise equality is vacuous. -/
example : ¬ Nonempty (Index (fun _ : Fin 1 => 0)) := by
  intro ⟨idx⟩
  exact Fin.elim0 (idx 0)

private def inner : Fin 1 → Axis := fun _ => ⟨3, 8, 1⟩
private def outer : Fin 1 → Axis := fun _ => ⟨1, 3, 1⟩
private def combined : Fin 1 → Axis := fun _ => ⟨4, 6, 1⟩
private def wrong : Fin 1 → Axis := fun _ => ⟨1, 3, 1⟩
private theorem validInner : ∀ i : Fin 1, IsWellFormed 10 5 (inner i) := by intro i; change IsWellFormed _ _ ⟨_, _, _⟩; decide
private theorem validOuter : ∀ i : Fin 1, IsWellFormed 5 2 (outer i) := by intro i; change IsWellFormed _ _ ⟨_, _, _⟩; decide
private theorem validCombined : ∀ i : Fin 1, IsWellFormed 10 2 (combined i) := by intro i; change IsWellFormed _ _ ⟨_, _, _⟩; decide
private theorem validWrong : ∀ i : Fin 1, IsWellFormed 10 2 (wrong i) := by intro i; change IsWellFormed _ _ ⟨_, _, _⟩; decide
private def point : Index (fun _ : Fin 1 => 2) := fun _ => ⟨1, by simp⟩
/-- Nonempty input, endpoint, and a well-typed wrong-offset negative control. -/
example : (sliceIndex inner validInner (sliceIndex outer validOuter point) 0).val = 5 := by decide
example : sliceIndex inner validInner (sliceIndex outer validOuter point) =
    sliceIndex combined validCombined point := by
  funext i
  have : i = 0 := by apply Fin.ext; have := i.isLt; omega
  subst i
  decide
example : sliceIndex inner validInner (sliceIndex outer validOuter point) ≠
    sliceIndex wrong validWrong point := by
  intro h
  have h0 := congrFun h 0
  have hv := congrArg Fin.val h0
  change 5 = 2 at hv
  contradiction
/-- The outer exclusive limit can meet the inner endpoint. -/
example : IsWellFormed 10 5 ⟨3, 8, 1⟩ ∧ IsWellFormed 5 3 ⟨2, 5, 1⟩ ∧
    IsWellFormed 10 3 ⟨5, 8, 1⟩ := by decide
end RevisedBenchmark.SliceComposeRank
