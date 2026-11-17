module
public import TensorRewrite.Pilot.LinearIndex
public import TensorRewrite.Pilot.Permutation
public import ShapeBridge

/-! Generic element-count facts; no rewrite-specific predicates. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.ElementCount
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex Heldout.ShapeBridge

/-- Scaling any one extent scales the total number of logical elements. -/
theorem scale_axis {rank : Nat} (shape : Shape rank) (axis : Fin rank) (factor : Nat) :
    elementCount (setExtent shape axis (factor * shape axis)) = factor * elementCount shape := by
  induction rank with
  | zero => exact Fin.elim0 axis
  | succ rank ih =>
    refine Fin.cases ?_ (fun tail => ?_) axis
    · have h : (fun i : Fin rank =>
          setExtent shape (0 : Fin (rank + 1)) (factor * shape 0) i.succ) =
          (fun i : Fin rank => shape i.succ) := by
        funext i
        simp [setExtent, Fin.succ_ne_zero]
      change setExtent shape 0 (factor * shape 0) 0 *
        elementCount (fun i => setExtent shape 0 (factor * shape 0) i.succ) =
        factor * (shape 0 * elementCount (fun i => shape i.succ))
      rw [h]
      simp [setExtent, Nat.mul_assoc]
    · have h : (fun i : Fin rank =>
          setExtent shape tail.succ (factor * shape tail.succ) i.succ) =
          setExtent (fun i : Fin rank => shape i.succ) tail (factor * shape tail.succ) := by
        funext i
        simp [setExtent, Fin.succ_inj]
      change setExtent shape tail.succ (factor * shape tail.succ) 0 *
        elementCount (fun i => setExtent shape tail.succ (factor * shape tail.succ) i.succ) =
        factor * (shape 0 * elementCount (fun i => shape i.succ))
      rw [h, ih]
      simp [setExtent, Ne.symm (Fin.succ_ne_zero tail), Nat.mul_left_comm]

/-- Redistribute a factor from one extent to another, including zero factors and extents. -/
theorem redistribute {rank : Nat} (shape : Shape rank) (split destination : Fin rank)
    (factor width : Nat) (product : shape split = factor * width) :
    elementCount (setExtent (setExtent shape split width) destination
      (factor * (setExtent shape split width) destination)) = elementCount shape := by
  let reduced := setExtent shape split width
  have recovered : setExtent reduced split (factor * reduced split) = shape := by
    funext i
    by_cases same : i = split
    · subst i
      simp [reduced, setExtent, product]
    · simp [reduced, setExtent, same]
  have fromSplit := scale_axis reduced split factor
  rw [recovered] at fromSplit
  exact (scale_axis reduced destination factor).trans fromSplit.symm

/-- The recursive shape count is the ordinary product over its finite axes. -/
theorem count_as_list {rank : Nat} (shape : Shape rank) :
    elementCount shape = ((List.finRange rank).map shape).prod := by
  induction rank with
  | zero => rfl
  | succ rank ih =>
    simp [elementCount, List.finRange_succ, List.map_map, ih, Function.comp_def]

/-- A finite axis permutation reorders, but does not change, the enumerated axes. -/
theorem permuted_axes {rank : Nat} (p : AxisPermutation rank) :
    ((List.finRange rank).map p.outputToInput).Perm (List.finRange rank) := by
  have injective : ∀ a b, p.outputToInput a = p.outputToInput b → a = b := by
    intro a b equal
    have h := congrArg p.inputToOutput equal
    simpa only [p.input_output] using h
  have unique : ((List.finRange rank).map p.outputToInput).Nodup := by
    apply List.Pairwise.map (R := fun a b : Fin rank => a ≠ b)
      (S := fun a b : Fin rank => a ≠ b) p.outputToInput
    · intro a b different equal
      exact different (injective a b equal)
    · exact List.nodup_finRange rank
  apply (List.perm_ext_iff_of_nodup unique (List.nodup_finRange rank)).mpr
  intro a
  constructor
  · intro _
    exact List.mem_finRange a
  · intro _
    exact List.mem_map.mpr ⟨p.inputToOutput a, List.mem_finRange _, p.output_input a⟩

/-- Permuting arbitrary-rank axes preserves the count, including all zero extents. -/
theorem permute_count {rank : Nat} (shape : Shape rank) (p : AxisPermutation rank) :
    elementCount (fun axis => shape (p.outputToInput axis)) = elementCount shape := by
  rw [count_as_list, count_as_list]
  have h := (permuted_axes p).map shape
  simpa [List.map_map, Function.comp_def] using h.prod_nat

#print axioms scale_axis
#print axioms redistribute
#print axioms count_as_list
#print axioms permuted_axes
#print axioms permute_count
end Heldout.ElementCount
