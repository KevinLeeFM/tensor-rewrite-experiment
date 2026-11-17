import TransSpec
set_option autoImplicit false
namespace RevisedBenchmark.TransArrays
open TensorRewrite.Pilot Tensor

private theorem lower {r : Nat} (f : Fin r → Fin r)
    (strict : ∀ i j, i < j → f i < f j) (i : Fin r) : i.val ≤ (f i).val := by
  rcases i with ⟨n,bound⟩
  induction n with
  | zero => exact Nat.zero_le _
  | succ n ih =>
    have prev : n < r := by omega
    have a := ih prev
    have b := strict ⟨n,prev⟩ ⟨n+1,bound⟩ (by change n < n+1; omega)
    change (f ⟨n,prev⟩).val < (f ⟨n+1,bound⟩).val at b
    change n ≤ (f ⟨n,prev⟩).val at a
    exact Nat.succ_le_of_lt (Nat.lt_of_le_of_lt a b)

theorem sortedForward : SortedForward := by
  intro r s t p h ordered
  have strict : ∀ i j, i < j → p.outputToInput i < p.outputToInput j := by
    intro i j less
    apply Nat.lt_of_le_of_ne (ordered i j less)
    intro eq
    have same := congrArg p.inputToOutput (Fin.ext eq)
    rw [p.input_output, p.input_output] at same
    exact (Fin.ne_of_lt less) same
  have forward : ∀ i, p.outputToInput i = i := by
    intro i
    have lo := lower _ strict i
    have upper := lower (fun t => (p.outputToInput t.rev).rev)
      (fun a b lt => Fin.rev_lt_rev.mpr (strict _ _ (Fin.rev_lt_rev.mpr lt))) i.rev
    simp only [Fin.rev_rev, Fin.val_rev] at upper
    have ix := i.isLt
    have fx := (p.outputToInput i).isLt
    exact Fin.ext (by omega)
  have backward : ∀ i, p.inputToOutput i = i := fun i =>
    (forward (p.inputToOutput i)).symm.trans (p.output_input i)
  have same : t = s := funext fun i => by simpa only [backward i] using h i
  subst t
  refine ⟨rfl, ?_⟩
  intro α x
  funext j
  apply congrArg x
  funext i
  apply Fin.ext
  change (j (p.inputToOutput i)).val = (j i).val
  rw [backward i]

theorem nested : Nested := by
  intro r s t u p q h g
  constructor
  · rw [AxisArray.composeLoop_eq_compose, AxisArray.ofPermutation_comp]
  · intro α x
    exact Transpose.transpose_comp p q h g x

theorem broadcastTranspose : BroadcastTranspose := by
  intro r s t a p legal h α x
  funext j
  apply congrArg x
  funext k
  apply Fin.ext
  change (j (a.decode k)).val = (j (p.outputToInput k)).val
  rw [legal k]

example : AxisArray.compose (#[1,2,0].toVector : AxisArray 3) (#[1,0,2].toVector : AxisArray 3) ≠
    AxisArray.compose (#[1,0,2].toVector : AxisArray 3) (#[1,2,0].toVector : AxisArray 3) := by
  intro eq
  have v := congrArg (fun a : AxisArray 3 => a[(0 : Fin 3)]) eq
  simp only [AxisArray.compose_get] at v
  exact (by decide : (2 : Fin 3) ≠ 0) v
#print axioms sortedForward
#print axioms nested
#print axioms broadcastTranspose
end RevisedBenchmark.TransArrays
