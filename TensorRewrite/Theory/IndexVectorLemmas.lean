module

public import TensorRewrite.Theory.IndexVector

/-! Coordinate inverses and lossless raw index-vector relayout, including empty extents. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.IndexVector

open Pilot

/-- Removing the inserted vector component recovers the original batch coordinate. -/
theorem batch_raw {components batchRank : Nat} {shape : Shape batchRank}
    (layout : Layout components shape) (batch : Index shape) (component : Fin components) :
    layout.batchIndex (layout.rawIndex batch component) = batch := by
  induction layout with
  | implicit => rfl
  | here => rfl
  | batch extent tail ih =>
    funext axis
    refine Fin.cases rfl (fun axis => ?_) axis
    exact congrFun (ih (fun axis => batch axis.succ) component) axis

/-- Recovering the vector component after insertion loses no information, including implicit
single-component vectors. Zero-component explicit vectors have no admitted component. -/
theorem component_raw {components batchRank : Nat} {shape : Shape batchRank}
    (layout : Layout components shape) (batch : Index shape) (component : Fin components) :
    layout.componentIndex (layout.rawIndex batch component) = component := by
  induction layout with
  | implicit => exact Subsingleton.elim _ _
  | here => rfl
  | batch extent tail ih => exact ih (fun axis => batch axis.succ) component

/-- Splitting and rebuilding an actual raw coordinate is the identity at every vector-axis
position and for an implicit representation. -/
theorem raw_split {components batchRank : Nat} {shape : Shape batchRank}
    (layout : Layout components shape) (raw : Index layout.rawShape) :
    layout.rawIndex (layout.batchIndex raw) (layout.componentIndex raw) = raw := by
  induction layout with
  | implicit => rfl
  | here =>
    funext axis
    exact Fin.cases rfl (fun _ => rfl) axis
  | batch extent tail ih =>
    funext axis
    refine Fin.cases rfl (fun axis => ?_) axis
    exact congrFun (ih (fun axis => raw axis.succ)) axis

/-- An explicit vector-axis position lies inside the actual raw tensor rank. -/
theorem vectorAxis_bound {components batchRank axis : Nat} {shape : Shape batchRank}
    (layout : Layout components shape) (present : layout.vectorAxis? = some axis) :
    axis < layout.rawRank := by
  induction layout generalizing axis with
  | implicit => cases present
  | here => cases present; exact Nat.zero_lt_succ _
  | batch extent tail ih =>
    cases found : tail.vectorAxis? with
    | none => simp [Layout.vectorAxis?, found] at present
    | some position =>
      have equal : position + 1 = axis := by simpa [Layout.vectorAxis?, found] using present
      have bound := ih found
      change axis < tail.rawRank + 1
      omega

/-- Absence of a vector dimension implies exactly one component, never an empty vector. -/
theorem implicit_components {components batchRank : Nat} {shape : Shape batchRank}
    (layout : Layout components shape) (absent : layout.vectorAxis? = none) : components = 1 := by
  induction layout with
  | implicit => rfl
  | here => cases absent
  | batch extent tail ih =>
    apply ih
    simpa [Layout.vectorAxis?] using absent

/-- Actual raw index element count is batch count times vector length, including zero-sized
explicit vectors and empty batches. -/
theorem elementCount_raw {components batchRank : Nat} {shape : Shape batchRank}
    (layout : Layout components shape) :
    LinearIndex.elementCount layout.rawShape = LinearIndex.elementCount shape * components := by
  induction layout with
  | implicit => exact (Nat.mul_one _).symm
  | here => exact Nat.mul_comm _ _
  | @batch components batchRank shape extent tail ih =>
    change extent * LinearIndex.elementCount tail.rawShape =
      (extent * LinearIndex.elementCount shape) * components
    rw [ih, Nat.mul_assoc]

/-- Reading a packed vector tensor recovers every original batch and component value. -/
theorem read_pack {components batchRank : Nat} {shape : Shape batchRank} {α : Type}
    (layout : Layout components shape) (values : Tensor shape (Fin components → α)) :
    read layout (pack layout values) = values := by
  funext batch component
  unfold read pack
  rw [batch_raw, component_raw]

/-- Packing the actual raw reader recovers every original raw index-tensor value. -/
theorem pack_read {components batchRank : Nat} {shape : Shape batchRank} {α : Type}
    (layout : Layout components shape) (raw : Tensor layout.rawShape α) :
    pack layout (read layout raw) = raw := by
  funext index
  change raw (layout.rawIndex (layout.batchIndex index) (layout.componentIndex index)) = raw index
  rw [raw_split]

/-- Scalar decoding or conversion commutes with actual raw coordinate reading; this does not
assert signed/unsigned decoders equivalent or authorize a narrowing conversion. -/
theorem read_map {components batchRank : Nat} {shape : Shape batchRank} {α β : Type}
    (layout : Layout components shape) (convert : α → β) (raw : Tensor layout.rawShape α) :
    read layout (Tensor.map convert raw) = fun batch component =>
      convert (read layout raw batch component) := rfl

/-- Moving or materializing the vector axis retains the complete actual batch/component tensor. -/
theorem read_relayout {components batchRank : Nat} {shape : Shape batchRank} {α : Type}
    (source target : Layout components shape) (raw : Tensor source.rawShape α) :
    read target (relayout source target raw) = read source raw :=
  read_pack target (read source raw)

/-- Relayout back into the same raw representation is the identity on actual tensors. -/
theorem relayout_refl {components batchRank : Nat} {shape : Shape batchRank} {α : Type}
    (layout : Layout components shape) (raw : Tensor layout.rawShape α) :
    relayout layout layout raw = raw := pack_read layout raw

/-- Two successive vector-axis relayouts equal the direct actual coordinate transformation. -/
theorem relayout_trans {components batchRank : Nat} {shape : Shape batchRank} {α : Type}
    (first second third : Layout components shape) (raw : Tensor first.rawShape α) :
    relayout second third (relayout first second raw) = relayout first third raw := by
  unfold relayout
  rw [read_pack]

end TensorRewrite.Theory.IndexVector
