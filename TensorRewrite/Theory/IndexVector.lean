module

public import TensorRewrite.Pilot.Tensor
public import TensorRewrite.Pilot.LinearIndexLemmas

/-! Bounded raw index-tensor coordinates with one explicit or implicit vector dimension. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.IndexVector

open Pilot

/-- One explicit vector axis anywhere in a raw tensor, or an implicit single-component vector.
The remaining batch shape and component count are fixed by the type. -/
inductive Layout : (components : Nat) → {batchRank : Nat} → Shape batchRank → Type where
  | implicit {batchRank : Nat} (shape : Shape batchRank) : Layout 1 shape
  | here {batchRank : Nat} (components : Nat) (shape : Shape batchRank) : Layout components shape
  | batch {components batchRank : Nat} {shape : Shape batchRank} (extent : Nat)
      (tail : Layout components shape) : Layout components (Fin.cases extent shape)

/-- Actual raw index-tensor rank, including an explicit vector dimension when present. -/
def Layout.rawRank : {components batchRank : Nat} → {shape : Shape batchRank} →
    Layout components shape → Nat
  | _, batchRank, _, .implicit _ => batchRank
  | _, batchRank, _, .here _ _ => batchRank + 1
  | _, _, _, .batch _ tail => tail.rawRank + 1

/-- Actual raw extents; an explicit zero-component vector remains a zero-sized dimension. -/
def Layout.rawShape : {components batchRank : Nat} → {shape : Shape batchRank} →
    (layout : Layout components shape) → Shape layout.rawRank
  | _, _, _, .implicit shape => shape
  | _, _, _, .here components shape => Fin.cases components shape
  | _, _, _, .batch extent tail => Fin.cases extent tail.rawShape

/-- The explicit vector-axis position, absent exactly for an implicit representation. -/
def Layout.vectorAxis? : {components batchRank : Nat} → {shape : Shape batchRank} →
    Layout components shape → Option Nat
  | _, _, _, .implicit _ => none
  | _, _, _, .here _ _ => some 0
  | _, _, _, .batch _ tail => tail.vectorAxis?.map Nat.succ

/-- Insert the actual bounded vector component at its declared raw axis. Implicit vectors
use the original batch coordinate and admit only their one component. -/
def Layout.rawIndex : {components batchRank : Nat} → {shape : Shape batchRank} →
    (layout : Layout components shape) → Index shape → Fin components → Index layout.rawShape
  | _, _, _, .implicit _, coordinate, _ => coordinate
  | _, _, _, .here _ _, coordinate, component => Fin.cases component coordinate
  | _, _, _, .batch _ tail, coordinate, component =>
    Fin.cases (coordinate ⟨0, Nat.zero_lt_succ _⟩)
      (tail.rawIndex (fun axis => coordinate axis.succ) component)

/-- Remove the actual vector axis from a raw coordinate, retaining every batch dimension. -/
def Layout.batchIndex : {components batchRank : Nat} → {shape : Shape batchRank} →
    (layout : Layout components shape) → Index layout.rawShape → Index shape
  | _, _, _, .implicit _, raw => raw
  | _, _, _, .here _ _, raw => fun axis => raw axis.succ
  | _, _, _, .batch _ tail, raw =>
    Fin.cases (raw ⟨0, Nat.zero_lt_succ _⟩) (tail.batchIndex (fun axis => raw axis.succ))

/-- Read the actual bounded vector component; the implicit representation has component zero. -/
def Layout.componentIndex : {components batchRank : Nat} → {shape : Shape batchRank} →
    (layout : Layout components shape) → Index layout.rawShape → Fin components
  | _, _, _, .implicit _, _ => 0
  | _, _, _, .here _ _, raw => raw ⟨0, Nat.zero_lt_succ _⟩
  | _, _, _, .batch _ tail, raw => tail.componentIndex (fun axis => raw axis.succ)

/-- Read actual raw tensor values as one component vector per bounded batch coordinate. -/
def read {components batchRank : Nat} {shape : Shape batchRank} {α : Type}
    (layout : Layout components shape) (raw : Tensor layout.rawShape α) :
    Tensor shape (Fin components → α) := fun batch component =>
  raw (layout.rawIndex batch component)

/-- Pack component vectors into their actual raw tensor shape and vector-axis position. -/
def pack {components batchRank : Nat} {shape : Shape batchRank} {α : Type}
    (layout : Layout components shape) (values : Tensor shape (Fin components → α)) :
    Tensor layout.rawShape α := fun raw =>
  values (layout.batchIndex raw) (layout.componentIndex raw)

/-- Move the vector axis or introduce/remove an explicit singleton vector axis by actual
bounded coordinate reads. This operation preserves the ordered batch/component interpretation. -/
def relayout {components batchRank : Nat} {shape : Shape batchRank} {α : Type}
    (source target : Layout components shape) (raw : Tensor source.rawShape α) :
    Tensor target.rawShape α := pack target (read source raw)

end TensorRewrite.Theory.IndexVector
