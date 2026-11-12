module

public import TensorRewrite.Theory.ReductionAlgebra
public import TensorRewrite.Pilot.ContractionRules
public import TensorRewrite.Theory.ConcatenationLemmas
public import Mathlib.Algebra.BigOperators.Ring.Finset

/-! Exact additive reduction and Dot over the paper's named coordinate groups. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.GroupedSums

open Pilot Theory Pilot.Contraction Pilot.Reduction

/-- Splitting and reassembling a bounded coordinate preserves every axis. -/
theorem appendIndex_projections {ar br : Nat} {a : Shape ar} {b : Shape br}
    (index : Index (appendShape a b)) :
    appendIndex (firstIndex index) (secondIndex index) = index := by
  funext axis
  refine Fin.addCases ?_ ?_ axis
  · intro i
    apply Fin.ext
    simp [appendIndex, firstIndex]
  · intro i
    apply Fin.ext
    simp [appendIndex, secondIndex]

/-- The paper's two disjoint axis groups enumerate exactly the combined bounded coordinates. -/
def groupEquiv {ar br : Nat} (a : Shape ar) (b : Shape br) :
    Index (appendShape a b) ≃ Index a × Index b where
  toFun index := (firstIndex index, secondIndex index)
  invFun pair := appendIndex pair.1 pair.2
  left_inv := appendIndex_projections
  right_inv pair := by
    apply Prod.ext
    · exact firstIndex_appendIndex pair.1 pair.2
    · exact secondIndex_appendIndex pair.1 pair.2

/-- A sum over the real combined shape is the sum over the two separate coordinate groups. -/
theorem sum_coordinate_groups {α : Type} [AddCommMonoid α] {ar br : Nat}
    (a : Shape ar) (b : Shape br) (f : Index a → Index b → α) :
    (∑ index : Index (appendShape a b), f (firstIndex index) (secondIndex index)) =
      ∑ pair : Index a × Index b, f pair.1 pair.2 :=
  Equiv.sum_comp (groupEquiv a b) (fun pair => f pair.1 pair.2)

/-- The existing Dot graph is a sum over its actual bounded contraction coordinates. -/
theorem dot_coordinate_sum {α : Type} [Semiring α] {batch left right contract : Nat}
    (plan : Contraction.Plan batch left right contract) (lhs : Tensor plan.lhsShape α)
    (rhs : Tensor plan.rhsShape α) (output : Index plan.outputShape) :
    dotTensor plan (· + ·) 0 (· * ·) id lhs rhs output =
      ∑ index : Index plan.contractShape,
        lhs (plan.lhsIndex output index) * rhs (plan.rhsIndex output index) := by
  simp only [dotTensor, terms, id_eq, FiniteSum.foldl_add_eq_sum, zero_add]
  rw [← Fin.sum_univ_def]
  exact Equiv.sum_comp (FiniteSum.indexEquiv plan.contractShape).symm
    (fun index => lhs (plan.lhsIndex output index) * rhs (plan.rhsIndex output index))

/-- The existing Reduce graph is a sum over its actual bounded reduction coordinates. -/
theorem reduce_coordinate_sum {α : Type} [AddCommMonoid α] (plan : Reduction.Plan)
    (input : Tensor plan.inputShape α) (output : Index plan.outputShape) :
    reduceTensor plan (· + ·) 0 input output =
      ∑ index : Index (ReductionFiber.shape plan),
        input (ReductionFiber.mergeIndex plan output index) := by
  simpa only [zero_add] using ReductionAlgebra.coordinate_sum plan (0 : α) input output

/-- `reduce/rule01`: products of independent reductions equal a product-fiber reduction. -/
theorem reduce_product {α : Type} [CommSemiring α] {ar br : Nat}
    (a : Shape ar) (b : Shape br) (x : Index a → α) (y : Index b → α) :
    (∑ i, x i) * (∑ j, y j) = ∑ pair : Index a × Index b, x pair.1 * y pair.2 := by
  rw [Fintype.sum_prod_type]
  simp only [Finset.sum_mul, Finset.mul_sum]
  exact Finset.sum_comm

/-- `reduce/rule05`: consecutive reductions equal one reduction over both groups. -/
theorem reduce_nested {α : Type} [AddCommMonoid α] {ar br cr : Nat}
    (a : Shape ar) (b : Shape br) (c : Shape cr) (x : Index a → Index b → Index c → α) :
    (fun k => ∑ j, ∑ i, x i j k) =
      (fun k => ∑ pair : Index a × Index b, x pair.1 pair.2 k) := by
  funext k
  rw [Fintype.sum_prod_type]
  exact Finset.sum_comm

/-- `dot/rule02`: swap operands and their labeled free-output coordinate groups. -/
theorem dot_swap {α : Type} [CommSemiring α] {kr br lr rr : Nat}
    (contract : Shape kr) (batch : Shape br) (left : Shape lr) (right : Shape rr)
    (x : Index batch → Index left → Index contract → α)
    (y : Index batch → Index right → Index contract → α) :
    (fun b l r => ∑ k, x b l k * y b r k) =
      (fun b l r => ∑ k, y b r k * x b l k) := by
  funext b l r
  apply Finset.sum_congr rfl
  intro k _
  exact mul_comm _ _

/-- Grouped Dot with no free axes on the right, evaluated at labeled output coordinates. -/
def dotNoRight {α : Type} [Semiring α] {br lr kr : Nat}
    (batch : Shape br) (left : Shape lr) (contract : Shape kr)
    (x : Index batch → Index left → Index contract → α)
    (y : Index batch → Index contract → α) : Index batch → Index left → α :=
  fun b l => ∑ k, x b l k * y b k

/-- Reduce the product of the left input and the right input broadcast over the left group. -/
def reduceBroadcastProduct {α : Type} [Semiring α] {br lr kr : Nat}
    (batch : Shape br) (left : Shape lr) (contract : Shape kr)
    (x : Index batch → Index left → Index contract → α)
    (y : Index batch → Index contract → α) : Index batch → Index left → α :=
  fun b l => ∑ k, (fun b l k => x b l k * y b k) b l k

/-- `dot/rule06`: Dot equals Reduce of the product with the right operand broadcast. -/
theorem dot_no_right {α : Type} [Semiring α] {br lr kr : Nat}
    (batch : Shape br) (left : Shape lr) (contract : Shape kr)
    (x : Index batch → Index left → Index contract → α)
    (y : Index batch → Index contract → α) :
    dotNoRight batch left contract x y = reduceBroadcastProduct batch left contract x y := rfl

/-- `reduce/rule06`: reducing a Dot batch group adds that group to the contraction. -/
theorem reduce_dot {α : Type} [Semiring α] {ar br lr rr : Nat}
    (a : Shape ar) (b : Shape br) (left : Shape lr) (right : Shape rr)
    (x : Index a → Index b → Index left → α)
    (y : Index a → Index b → Index right → α) :
    (fun l r => ∑ j, ∑ i, x i j l * y i j r) =
      (fun l r => ∑ pair : Index a × Index b, x pair.1 pair.2 l * y pair.1 pair.2 r) := by
  funext l r
  rw [Fintype.sum_prod_type]
  exact Finset.sum_comm

/-- `reduce/rule04`: exchanging labels before reduction preserves values and remaining labels. -/
theorem relabel_reduce {α : Type} (plan : Reduction.Plan) (operation : α → α → α)
    (initial : α) (input : Tensor plan.inputShape α) :
    reduceTensor plan operation initial
        (Tensor.transpose (AxisPermutation.identity plan.inputRank) (fun _ => rfl) input) =
      Tensor.transpose (AxisPermutation.identity plan.outputRank) (fun _ => rfl)
        (reduceTensor plan operation initial input) := rfl

/-- Read a pair of actual Concat blocks using their bounded left/right segment coordinates. -/
theorem concat_pair_coordinate {rank : Nat} {frame : Theory.Concatenation.Frame rank} {α : Type}
    (first second : Theory.Concatenation.Block frame α) (rest : Index (frame.shape 1))
    (position : Fin (first.extent + second.extent)) :
    Theory.Concatenation.readAt [first, second] rest position.val (by
        simp [Theory.Concatenation.total]) =
      Fin.addCases (fun i => first.values (frame.withPosition rest i))
        (fun i => second.values (frame.withPosition rest i)) position := by
  refine Fin.addCases ?_ ?_ position
  · intro index
    have bound := index.isLt
    simp [Theory.Concatenation.readAt, bound]
  · intro index
    have bound := index.isLt
    simp [Theory.Concatenation.readAt]

/-- `dot/rule01`: a paired Concat Dot is the sum of its two separate Dots. -/
theorem dot_concat {α : Type} [Semiring α] {m n lr rr : Nat}
    (left : Shape lr) (right : Shape rr)
    (x : Index left → Fin m → α) (y : Index left → Fin n → α)
    (c : Index right → Fin m → α) (d : Index right → Fin n → α) :
    (fun (l : Index left) (r : Index right) => ∑ k : Fin (m + n), (Fin.addCases (x l) (y l) k : α) *
        (Fin.addCases (c r) (d r) k : α)) =
      (fun (l : Index left) (r : Index right) => ∑ segment : Fin 2, (Fin.cases
        (∑ k, x l k * c r k) (fun _ => ∑ k, y l k * d r k) segment : α)) := by
  funext l r
  rw [Fin.sum_univ_add]
  simp [Fin.sum_univ_two]
  rfl

/-- `reduce/rule02`: reduce separately or reduce their actual concatenated axis. -/
theorem reduce_concat {α : Type} [AddCommMonoid α] {m n otherRank : Nat}
    (other : Shape otherRank) (x : Fin m → Index other → α) (y : Fin n → Index other → α) :
    (fun (remaining : Index other) => ∑ segment : Fin 2,
        (Fin.cases (∑ i, x i remaining) (fun _ => ∑ j, y j remaining) segment : α)) =
      (fun (remaining : Index other) => ∑ i : Fin (m + n),
        (Fin.addCases (fun i => x i remaining) (fun j => y j remaining) i : α)) := by
  funext remaining
  rw [Fin.sum_univ_add]
  simp [Fin.sum_univ_two]
  rfl

/-- The labeled Dot associativity statement that the paper artifact accidentally did not run. -/
theorem dot_associativity {α : Type} [Semiring α] {ar br cr dr : Nat}
    (a : Shape ar) (b : Shape br) (c : Shape cr) (d : Shape dr)
    (x : Index a → Index b → α) (y : Index b → Index c → α)
    (z : Index c → Index d → α) :
    (fun i k => ∑ j, x i j * (∑ l, y j l * z l k)) =
      (fun i k => ∑ l, (∑ j, x i j * y j l) * z l k) := by
  funext i k
  simp only [Finset.mul_sum, Finset.sum_mul, mul_assoc]
  exact Finset.sum_comm

#print axioms appendIndex_projections
#print axioms sum_coordinate_groups
#print axioms dot_coordinate_sum
#print axioms reduce_coordinate_sum
#print axioms reduce_product
#print axioms reduce_nested
#print axioms dot_swap
#print axioms dot_no_right
#print axioms reduce_dot
#print axioms relabel_reduce
#print axioms concat_pair_coordinate
#print axioms dot_concat
#print axioms reduce_concat
#print axioms dot_associativity

end TensorRewrite.PaperComparison.GroupedSums
