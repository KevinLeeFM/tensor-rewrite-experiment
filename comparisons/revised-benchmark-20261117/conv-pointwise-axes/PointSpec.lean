module
public import Std
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.ConvPointAxes

/-- One spatial axis; the kernel's first two roles are input and output
feature, respectively. Physical storage access uses three numbered axes. -/
inductive Role where | batch | feature | space deriving DecidableEq, Repr
structure Order where
  slot : Role → Fin 3
  role : Fin 3 → Role
  slot_role : ∀ p, slot (role p) = p
  role_slot : ∀ a, role (slot a) = a

abbrev Coord := Fin 3 → Nat
def place (perm : Order) (b f s : Nat) : Coord := fun p =>
  match perm.role p with
  | .batch => b | .feature => f | .space => s

/-- The generated transpose array maps an output position to its operand axis. -/
def permutation (source result : Order) (p : Fin 3) := source.slot (result.role p)
def inverseRead (source result : Order) (y : Coord) : Coord := fun p =>
  y (permutation result source p)
def Fits (shape index : Coord) := ∀ p, index p < shape p
abbrev Tensor (shape : Coord) := {i : Coord // Fits shape i} → Nat
def read {shape : Coord} (a : Tensor shape) (i : Coord) :=
  if h : ∀ p, i p < shape p then a ⟨i,h⟩ else 0

structure Sizes where
  batch : Nat
  groups : Nat
  batches : Nat
  spatial : Nat
def Legal (s : Sizes) := 0 < s.groups ∧ 0 < s.batches ∧
  ¬ (1 < s.batches ∧ 1 < s.groups) ∧ s.groups % s.batches = 0 ∧
  s.batch % s.batches = 0
def lhsShape (s : Sizes) (l : Order) := place l s.batch s.groups s.spatial
def rhsShape (s : Sizes) (k : Order) := place k 1 s.groups 1
def outShape (s : Sizes) (o : Order) := place o (s.batch / s.batches) s.groups s.spatial

/-- Grouped convolution operand addresses for an output and a kernel tap. -/
def oldL (s : Sizes) (l o : Order) (y : Coord) (tap channel : Nat) : Coord :=
  let z := y (o.slot .feature)
  let bg := z / (s.groups / s.batches)
  let fg := z / (s.groups / s.groups)
  place l (y (o.slot .batch) + bg*(s.batch/s.batches))
    (fg*(s.groups/s.groups)+channel) (y (o.slot .space)+tap)
def oldK (k o : Order) (y : Coord) (tap channel : Nat) :=
  place k channel (y (o.slot .feature)) tap

/-- BroadcastSequence retains equal-extent dimensions (even if extent one);
on unequal dimensions the valid kernel extent must be one. Its squeeze followed
by ordered broadcast reinserts coordinate zero at each dropped axis. -/
def broadcastRead (fromShape toShape y : Coord) : Coord :=
  fun p => if fromShape p = toShape p then y p else 0

def doConv (s : Sizes) (l k o : Order) (y : Coord)
    (x : Tensor (lhsShape s l)) (w : Tensor (rhsShape s k)) :=
  ((List.range 1).flatMap fun tap => (List.range (s.groups / s.groups)).map fun ch =>
    read x (oldL s l o y tap ch) * read w (oldK k o y tap ch)).sum

def newK (s : Sizes) (k o : Order) (y : Coord) :=
  inverseRead k o (broadcastRead (place o 1 s.groups 1) (lhsShape s o) y)
def product (s : Sizes) (l k o : Order) (y : Coord)
    (x : Tensor (lhsShape s l)) (w : Tensor (rhsShape s k)) :=
  read x (inverseRead l o y) * read w (newK s k o y)

def Goal := ∀ (s : Sizes), Legal s → s.batches = 1 ∧
  ∀ (l k o : Order),
  (∀ p, permutation l o (permutation o l p) = p ∧
        permutation k o (permutation o k p) = p) ∧
  outShape s o = lhsShape s o ∧
  (∀ p, lhsShape s l (permutation l o p) = lhsShape s o p ∧
        rhsShape s k (permutation k o p) = place o 1 s.groups 1 p ∧
        (place o 1 s.groups 1 p = lhsShape s o p ∨ place o 1 s.groups 1 p = 1)) ∧
  ∀ (y : Coord), Fits (outShape s o) y →
  Fits (lhsShape s l) (inverseRead l o y) ∧ Fits (rhsShape s k) (newK s k o y) ∧
  oldL s l o y 0 0 = inverseRead l o y ∧ oldK k o y 0 0 = newK s k o y ∧
  ∀ x w, doConv s l k o y x w = product s l k o y x w
end RevisedBenchmark.ConvPointAxes
