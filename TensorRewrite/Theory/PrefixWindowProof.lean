module

public import TensorRewrite.Theory.PrefixWindowSampling
public import TensorRewrite.Theory.FiniteSum

/-! Exact cumulative-window lists and counts, with initializer and arithmetic domains explicit. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.PrefixWindow

open Pilot

/-- The complete ordered window list is leading padding followed by the actual input prefix. -/
theorem values_prefix {rank : Nat} {α : Type} (plan : Plan rank) (padding : α)
    (input : Tensor (windowPlan plan).inputShape α)
    (output : Index (windowPlan plan).outputShape) :
    ReductionWindow.values (windowPlan plan) padding input output =
      List.replicate (paddingCount plan output) padding ++ prefixValues plan input output := by
  rw [values_scan_range, split_kernel_range]
  congr 1
  · trans (List.finRange (paddingCount plan output)).map (fun _ => padding)
    · apply List.map_congr_left
      intro position _
      unfold ReductionWindow.contribution
      rw [sample_invalid plan output _ (by exact position.isLt)]
    · rw [List.map_const', List.length_finRange]
  · unfold prefixValues
    apply List.map_congr_left
    intro position _
    unfold ReductionWindow.contribution
    rw [sample_valid plan output _ (by dsimp; omega)]
    dsimp only
    apply congrArg input
    unfold sampledIndex
    apply congrArg (replaceCoordinate plan (outputIndex plan output))
    apply Fin.ext
    dsimp only
    omega

/-- Only the initializer's padding fixed point is needed to discard the leading padding block. -/
theorem reduce_prefix {rank : Nat} {α : Type} (plan : Plan rank) (operation : α → α → α)
    (initial padding : α) (fixed : operation initial padding = initial)
    (input : Tensor (windowPlan plan).inputShape α) :
    ReductionWindow.reduce (windowPlan plan) operation initial padding input =
      fun output => (prefixValues plan input output).foldl operation initial := by
  funext output
  change (ReductionWindow.values _ _ _ _).foldl operation initial = _
  rw [values_prefix, List.foldl_append,
    ReductionWindow.foldl_replicate_fixed operation initial padding fixed]

/-- Every inclusive prefix has exactly one more element than its scan output coordinate. -/
theorem prefix_length {rank : Nat} {α : Type} (plan : Plan rank)
    (input : Tensor (windowPlan plan).inputShape α)
    (output : Index (windowPlan plan).outputShape) :
    (prefixValues plan input output).length =
      (coordinate plan (outputIndex plan output)).val + 1 := by
  simp [prefixValues]

/-- A uniform input repeats its value once per actual prefix element. -/
theorem prefix_constant {rank : Nat} {α : Type} (plan : Plan rank) (value : α)
    (output : Index (windowPlan plan).outputShape) :
    prefixValues plan (Tensor.constant value) output =
      List.replicate ((coordinate plan (outputIndex plan output)).val + 1) value := by
  simp [prefixValues, Tensor.constant]

/-- Exact additive cumulative windows retain the initializer plus the inclusive prefix sum. -/
theorem additive_prefix {rank : Nat} {α : Type} [AddMonoid α] (plan : Plan rank)
    (initial : α) (input : Tensor (windowPlan plan).inputShape α) :
    ReductionWindow.reduce (windowPlan plan) (· + ·) initial 0 input =
      fun output => initial + (prefixValues plan input output).sum := by
  rw [reduce_prefix plan (· + ·) initial 0 (add_zero initial)]
  funext output
  exact FiniteSum.foldl_add_eq_sum _ _

/-- Exact uniform cumulative sums are the true prefix count acting on the value. -/
theorem constant_additive_prefix {rank : Nat} {α : Type} [AddMonoid α] (plan : Plan rank)
    (initial value : α) :
    ReductionWindow.reduce (windowPlan plan) (· + ·) initial 0 (Tensor.constant value) =
      fun output => initial + ((coordinate plan (outputIndex plan output)).val + 1) • value := by
  rw [additive_prefix]
  funext output
  rw [prefix_constant, List.sum_replicate]

/-- Counting ones from zero yields coordinate+1 over the mathematical natural numbers. -/
theorem natural_prefix_count {rank : Nat} (plan : Plan rank) :
    ReductionWindow.reduce (windowPlan plan) (· + ·) 0 0 (Tensor.constant (1 : Nat)) =
      fun output => (coordinate plan (outputIndex plan output)).val + 1 := by
  rw [constant_additive_prefix]
  funext output
  simp

end TensorRewrite.Theory.PrefixWindow
