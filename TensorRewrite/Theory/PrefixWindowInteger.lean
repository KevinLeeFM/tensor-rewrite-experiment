module

public import TensorRewrite.Theory.PrefixWindowProof
public import TensorRewrite.Theory.PrefixWindowArithmetic

/-! Broadcast times inclusive Iota for exact semirings and modular words, with conversion bounds. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.PrefixWindow

open Pilot

/-- Exact semiring cumulative constants equal the scalar times the inclusive coordinate. -/
theorem semiring_prefix_product {rank : Nat} {α : Type} [Semiring α] (plan : Plan rank)
    (value : α) :
    ReductionWindow.reduce (windowPlan plan) (· + ·) 0 0 (Tensor.constant value) =
      Tensor.map₂ (· * ·) (Tensor.constant value)
        (fun output => ((coordinate plan (outputIndex plan output)).val : α) + 1) := by
  rw [constant_additive_prefix]
  funext output
  simpa only [Tensor.map₂, Tensor.constant, zero_add, Nat.cast_add, Nat.cast_one] using
    (nsmul_eq_mul' value ((coordinate plan (outputIndex plan output)).val + 1))

/-- Modular cumulative constants equal Broadcast(value) times the same-width inclusive Iota. -/
theorem word_prefix_product {rank : Nat} (plan : Plan rank) (width : Nat) (value : BitVec width) :
    ReductionWindow.reduce (windowPlan plan) (· + ·) 0 0 (Tensor.constant value) =
      Tensor.map₂ (· * ·) (Tensor.constant value) (fun output =>
        BitVec.ofNat width (coordinate plan (outputIndex plan output)).val + 1#width) := by
  rw [reduce_prefix plan (· + ·) 0 0 (BitVec.add_zero _)]
  funext output
  rw [prefix_constant, word_replicate_fold]
  change (0#width) + BitVec.ofNat width
    ((coordinate plan (outputIndex plan output)).val + 1) * value = _
  rw [BitVec.zero_add]
  simp only [BitVec.ofNat_add, Tensor.map₂, Tensor.constant]
  exact BitVec.mul_comm _ _

/-- Modular prefix counts are the actual count reduced modulo the selected width. -/
theorem word_prefix_count {rank : Nat} (plan : Plan rank) (width : Nat) :
    ReductionWindow.reduce (windowPlan plan) (· + ·) 0 0 (Tensor.constant (1#width)) =
      fun output => BitVec.ofNat width ((coordinate plan (outputIndex plan output)).val + 1) := by
  rw [word_prefix_product]
  funext output
  simp only [Tensor.map₂, Tensor.constant, BitVec.one_mul, BitVec.ofNat_add]

/-- Unsigned observations of the actual prefix-count reduction are exact precisely below 2^width. -/
theorem word_prefix_unsigned_iff {rank : Nat} (plan : Plan rank) (width : Nat)
    (output : Index (windowPlan plan).outputShape) :
    (ReductionWindow.reduce (windowPlan plan) (· + ·) 0 0
      (Tensor.constant (1#width)) output).toNat =
      (coordinate plan (outputIndex plan output)).val + 1 ↔
      (coordinate plan (outputIndex plan output)).val + 1 < 2 ^ width := by
  rw [word_prefix_count]
  exact unsigned_count_exact_iff _ _

/-- Signed count observations are exact precisely within the nonnegative signed range. -/
theorem word_prefix_signed_iff {rank : Nat} (plan : Plan rank) (width : Nat)
    (output : Index (windowPlan plan).outputShape) :
    (ReductionWindow.reduce (windowPlan plan) (· + ·) 0 0
      (Tensor.constant (1#width)) output).toInt =
      ((coordinate plan (outputIndex plan output)).val + 1 : Nat) ↔
      2 * ((coordinate plan (outputIndex plan output)).val + 1) < 2 ^ width := by
  rw [word_prefix_count]
  exact signed_count_exact_iff _ _

/-- The 32-bit Iota/product value theorem retains modular wraparound. -/
theorem i32_prefix_product {rank : Nat} (plan : Plan rank) (value : BitVec 32) :
    ReductionWindow.reduce (windowPlan plan) (· + ·) 0 0 (Tensor.constant value) =
      Tensor.map₂ (· * ·) (Tensor.constant value) (fun output =>
        BitVec.ofNat 32 (coordinate plan (outputIndex plan output)).val + 1#32) :=
  word_prefix_product plan 32 value

/-- The 64-bit counterpart has the same modular contract and arbitrary scan extent. -/
theorem i64_prefix_product {rank : Nat} (plan : Plan rank) (value : BitVec 64) :
    ReductionWindow.reduce (windowPlan plan) (· + ·) 0 0 (Tensor.constant value) =
      Tensor.map₂ (· * ·) (Tensor.constant value) (fun output =>
        BitVec.ofNat 64 (coordinate plan (outputIndex plan output)).val + 1#64) :=
  word_prefix_product plan 64 value

end TensorRewrite.Theory.PrefixWindow
