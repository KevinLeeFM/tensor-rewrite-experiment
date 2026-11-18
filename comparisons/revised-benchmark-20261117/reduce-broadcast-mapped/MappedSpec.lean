module
public import Std
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.ReduceMapped

/-- Major-to-minor interleaving for a strictly increasing equal-extent broadcast.
Added axes survive; original axes can survive or be reduced. -/
inductive Axis where
  | added (n : Nat) | kept (n : Nat) | reduced (n : Nat)
deriving Repr, DecidableEq

/-- Raw major-to-minor dimensions for the broadcasted reduction. -/
def dims : List Axis → List (Nat × Bool)
  | [] => []
  | .added n :: t | .kept n :: t => (n,false) :: dims t
  | .reduced n :: t => (n,true) :: dims t

/-- Actual operand shape and reduction roles after inverting the ordered map. -/
def baseDims : List Axis → List (Nat × Bool)
  | [] => []
  | .added _ :: t => baseDims t
  | .kept n :: t => (n,false) :: baseDims t
  | .reduced n :: t => (n,true) :: baseDims t

/-- Project a full broadcasted coordinate to the physical base coordinate. -/
def originalRead : List Axis → List Nat → List Nat
  | [], _ => []
  | .added _ :: t, x => originalRead t x.tail
  | .kept _ :: t, x | .reduced _ :: t, x => x.headD 0 :: originalRead t x.tail

/-- Generate ordered full-coordinate reads, substituting output coordinates
on surviving axes and enumerating every reduced coordinate in lexical order. -/
def reads : List (Nat × Bool) → List Nat → List (List Nat)
  | [], _ => [[]]
  | (n,true) :: t, out =>
    (List.range n).flatMap fun d => (reads t out).map (d :: ·)
  | (_,false) :: t, out => (reads t out.tail).map (out.headD 0 :: ·)

/-- Iterate physical axes: physical is the current old target-axis number,
deleted counts preceding reduced axes. Emit the source's subtraction. -/
def emitted : List Axis → Nat → Nat → List Nat
  | [], _, _ => []
  | .reduced _ :: t, physical, deleted => emitted t (physical+1) (deleted+1)
  | .added _ :: t, physical, deleted => emitted t (physical+1) deleted
  | .kept _ :: t, physical, deleted =>
    (physical-deleted) :: emitted t (physical+1) deleted

def newOut (ds : List Axis) (out : List Nat) :=
  (emitted ds 0 0).map (fun i => out[i]?.getD 0)

def outputShape (ds : List (Nat × Bool)) := (ds.filter fun d => !d.2).map Prod.fst
def valid : List Nat → List Nat → Prop
  | [], [] => True
  | n::ns, x::xs => x < n ∧ valid ns xs
  | _, _ => False

def Goal := ∀ (ds : List Axis) (out : List Nat),
  valid (outputShape (dims ds)) out →
  valid (outputShape (baseDims ds)) (newOut ds out) ∧
  (reads (dims ds) out).map (originalRead ds) = reads (baseDims ds) (newOut ds out) ∧
  ∀ (α : Type) (x : List Nat → α) (seed : α) (op : α → α → α),
    (reads (dims ds) out).foldl (fun a c => op a (x (originalRead ds c))) seed =
    (reads (baseDims ds) (newOut ds out)).foldl (fun a c => op a (x c)) seed
end RevisedBenchmark.ReduceMapped
