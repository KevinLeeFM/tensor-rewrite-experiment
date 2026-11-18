module
public import PointProof
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.ConvFullTaps
open ConvPointAxes

def win (n w : Nat) := ((n : Int)-w+1).toNat
def finalShape (s : Sizes) (w : Nat) (o : Order) :=
  place o (s.batch/s.batches) s.groups (win s.spatial w)
def kernelShape (s : Sizes) (w : Nat) (k : Order) := place k 1 s.groups w

def flipTap (rev : Bool) (w i : Nat) := if rev then w-1-i else i
def oldTerms (s : Sizes) (w : Nat) (l k o : Order) (rev : Bool) (y : Coord) :=
  (List.range w).flatMap fun t => (List.range (s.groups/s.groups)).map fun c =>
    (oldL s l o y t c, oldK k o y (flipTap rev w t) c)

/-- A rank-two reduced coordinate is y restricted to the two physical
nonspatial axes. Reinsert the variable reduction index at the erased slot. -/
def insertTap (o : Order) (y : Coord) (t : Nat) : Coord := fun p =>
  if p = o.slot .space then t else y p

/-- Reverse before transposing: reverse lookup modifies the original *kernel*
physical spatial position after transpose and broadcast have been pulled back. -/
def reversedRead (k : Order) (rev : Bool) (w : Nat) (v : Coord) : Coord := fun p =>
  if p = k.slot .space then flipTap rev w (v p) else v p

def newPair (s : Sizes) (w : Nat) (l k o : Order) (rev : Bool) (y : Coord) (t : Nat) :=
  let c := insertTap o y t
  let b := broadcastRead (kernelShape s w o) (lhsShape s o) c
  (inverseRead l o c, reversedRead k rev w (inverseRead k o b))
def newTerms (s : Sizes) (w : Nat) (l k o : Order) (rev : Bool) (y : Coord) :=
  (List.range s.spatial).map (newPair s w l k o rev y)

def contract {sx sw : Coord} (x : Tensor sx) (k : Tensor sw) (reads : List (Coord × Coord)) :=
  (reads.map fun (a,b) => read x a * read k b).foldl (·+·) 0

/-- Dense row-major packing, over the whole final rank or its two retained
physical axes in the same order. -/
def pack (shape y : Coord) (acc : Nat) (ps : List (Fin 3)) :=
  ps.foldl (fun pos p => pos * shape p + y p) acc
def deleted (o : Order) := (List.finRange 3).filter (fun p => p != o.slot .space)

def Goal := ∀ (s : Sizes) (w : Nat), Legal s → 0 < w → w ≠ 1 → win s.spatial w = 1 →
  s.spatial = w ∧ s.batches = 1 ∧ ∀ (l k o : Order) (rev : Bool) (y : Coord),
  Fits (finalShape s w o) y →
  pack (finalShape s w o) y 0 (List.finRange 3) = pack (lhsShape s o) y 0 (deleted o) ∧
  oldTerms s w l k o rev y = newTerms s w l k o rev y ∧
  (∀ t < s.spatial, Fits (lhsShape s l) (newPair s w l k o rev y t).1 ∧
    Fits (kernelShape s w k) (newPair s w l k o rev y t).2) ∧
  ∀ (x : Tensor (lhsShape s l)) (kernel : Tensor (kernelShape s w k)),
    contract x kernel (oldTerms s w l k o rev y) =
    contract x kernel (newTerms s w l k o rev y)
end RevisedBenchmark.ConvFullTaps
