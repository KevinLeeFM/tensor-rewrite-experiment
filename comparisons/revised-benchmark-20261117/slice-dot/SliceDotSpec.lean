import Std
set_option autoImplicit false
namespace RevisedBenchmark.SliceDot

/-- Labels of physical axes. The numeral is the ordinal in the dnums batch or
contract list, or the ordinal among free axes in increasing physical order. -/
inductive Axis (b f k : Nat) where
  | batch (i : Fin b) | free (i : Fin f) | contract (i : Fin k)
deriving DecidableEq, Repr

/-- The physical axis list contains each role exactly once with free axes in order.
Batch and contracting lists may be ordered arbitrarily and differently on the two operands. -/
def Lawful {b f k : Nat} (axes : List (Axis b f k)) : Prop :=
  axes.Perm ((List.ofFn Axis.batch) ++ (List.ofFn Axis.free) ++ (List.ofFn Axis.contract)) ∧
  axes.filterMap (fun | .free i => some i | _ => none) = List.ofFn id

structure Slice where
  start : Nat
  limit : Nat
  stride : Nat
deriving DecidableEq, Repr

def whole (n : Nat) : Slice := ⟨0,n,1⟩
def width (s : Slice) := (s.limit - s.start + s.stride - 1) / s.stride
def atCoord (s : Slice) (i : Nat) := s.start + i * s.stride

/-- ConstructToDotMaps writes paired batch ordinals first, then lhs-free axes,
then rhs-free axes, with no output slot for contracting axes. -/
def slot {b f k : Nat} (freeOffset : Nat) : Axis b f k → Option Nat
  | .batch i => some i.val
  | .free i => some (freeOffset + i.val)
  | .contract _ => none

def extent {b f k : Nat} (offset : Nat) (out : Nat → Nat) (ks : Fin k → Nat)
    (a : Axis b f k) := match a with
  | .contract i => ks i
  | _ => out ((slot offset a).getD 0)

def project {b f k : Nat} (offset : Nat) (ks : Fin k → Nat) (s : Nat → Slice)
    (a : Axis b f k) := match a with
  | .contract i => whole (ks i)
  | _ => s ((slot offset a).getD 0)

/-- Build operand positions in physical axis order. The kth paired contraction
coordinate is read only on a contracting axis. -/
def readAt {b f k : Nat} (offset : Nat) (q : Nat → Nat) (t : List Nat)
    (a : Axis b f k) := match a with
  | .contract i => t[i.val]?.getD 0
  | _ => q ((slot offset a).getD 0)

def grid : List Nat → List (List Nat)
  | [] => [[]]
  | n :: ns => (List.range n).flatMap (fun i => (grid ns).map (i :: ·))

def dot (ks : List Nat) (lhs rhs : List Nat → Int) :=
  ((grid ks).map (fun t => lhs t * rhs t)).sum

/-- Original dot at the sampled output coordinate. -/
def originalOperand {b f k : Nat} (axes : List (Axis b f k)) (offset : Nat)
    (s : Nat → Slice) (q : Nat → Nat) (x : List Nat → Int) (t : List Nat) :=
  x (axes.map (readAt offset (fun j => atCoord (s j) (q j)) t))

/-- Source creates a slice only when at least one physical dimension changes.
For valid limits, a non-full descriptor is exactly the source update flag. -/
def replacementOperand {b f k : Nat} (axes : List (Axis b f k)) (offset : Nat)
    (out : Nat → Nat) (ks : Fin k → Nat) (s : Nat → Slice) (q : Nat → Nat)
    (x : List Nat → Int) (t : List Nat) :=
  let attrs := project offset ks s
  if axes.any (fun a => decide (attrs a ≠ whole (extent offset out ks a))) then
    x (axes.map (fun a => atCoord (attrs a) (readAt offset q t a)))
  else x (axes.map (readAt offset q t))

/-- Input and output shapes in physical order. Shared output extents encode
paired batch compatibility; shared ks encode paired contraction compatibility. -/
def projectedShape {b f k : Nat} (axes : List (Axis b f k)) (offset : Nat)
    (ks : Fin k → Nat) (s : Nat → Slice) :=
  axes.map (fun a => width (project offset ks s a))

def Case : Prop := ∀ {b l r k : Nat} (lhs : List (Axis b l k)) (rhs : List (Axis b r k))
    (out : Nat → Nat) (ks : Fin k → Nat) (s : Nat → Slice),
  Lawful lhs → Lawful rhs →
  (∀ j, j < b+l+r → (s j).start ≤ (s j).limit ∧ (s j).limit ≤ out j ∧ 0 < (s j).stride) →
  projectedShape lhs b ks s = lhs.map (extent b (fun j => width (s j)) ks) ∧
  projectedShape rhs (b+l) ks s = rhs.map (extent (b+l) (fun j => width (s j)) ks) ∧
  ∀ (x y : List Nat → Int) (q : Nat → Nat), (∀ j, j < b+l+r → q j < width (s j)) →
    dot (List.ofFn ks) (originalOperand lhs b s q x) (originalOperand rhs (b+l) s q y) =
    dot (List.ofFn (fun i => width (project b ks s (Axis.contract (b:=b) (f:=l) i))))
      (replacementOperand lhs b out ks s q x) (replacementOperand rhs (b+l) out ks s q y)
end RevisedBenchmark.SliceDot
