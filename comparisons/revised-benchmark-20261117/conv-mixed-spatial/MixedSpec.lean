module
public import PointProof
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.ConvMixedSpatial
open ConvPointAxes
/-- Ordered physical axis slots 0,1,2,3. -/
structure Four where
  a : Nat
  b : Nat
  c : Nat
  d : Nat
deriving DecidableEq, Repr
def Fits (z s : Four) := z.a<s.a ∧ z.b<s.b ∧ z.c<s.c ∧ z.d<s.d
instance (z s : Four) : Decidable (Fits z s) := by unfold Fits; infer_instance
abbrev Arr (s : Four) := {z // Fits z s} → Nat
def read {s : Four} (x : Arr s) (z : Four) := if h : Fits z s then x ⟨z,h⟩ else 0
def win (n w : Nat) := ((n:Int)-w+1).toNat
def input (s : Sizes) (c : Nat) : Four := ⟨s.spatial,s.batch,c,s.groups⟩
def kernel (s : Sizes) (w : Nat) : Four := ⟨1,s.groups,w,1⟩
def out (s : Sizes) (w c : Nat) : Four := ⟨s.groups,win s.spatial w,win c 1,s.batch/s.batches⟩
def flip (r : Bool) (w i : Nat) := if r then w-1-i else i
/-- Grouped forward convolution at original physical offsets. -/
def oldPair (s : Sizes) (w : Nat) (r rc : Bool) (y : Four) (t k ch : Nat) : Four × Four :=
  let channels := s.groups/s.groups
  (⟨y.b+t,y.d+(y.a/(s.groups/s.batches))*(s.batch/s.batches),y.c+k,
     (y.a/channels)*channels+ch⟩,
    ⟨flip rc 1 k,y.a,flip r w t,ch⟩)
def oldTerms (s : Sizes) (w : Nat) (r rc : Bool) (y : Four) :=
  (List.range w).flatMap fun t => (List.range 1).flatMap fun k =>
    (List.range (s.groups/s.groups)).map fun ch => oldPair s w r rc y t k ch
/-- Pull the input transpose [3,0,2,1] and kernel transpose [1,2,0,3]
    back to the numbered physical slots of each original array. -/
def lhsBack (p : Four) : Four := ⟨p.b,p.d,p.c,p.a⟩
def kerBack (p : Four) : Four := ⟨p.c,p.a,p.b,p.d⟩
def broadcast (src dst z : Four) : Four :=
  ⟨if src.a=dst.a then z.a else 0, if src.b=dst.b then z.b else 0,
   if src.c=dst.c then z.c else 0, if src.d=dst.d then z.d else 0⟩
def newPair (s : Sizes) (w c : Nat) (r : Bool) (y : Four) (t : Nat) : Four × Four :=
  let z : Four := ⟨y.a,t,y.c,y.d⟩
  let k := kerBack (broadcast ⟨s.groups,w,1,1⟩ ⟨s.groups,s.spatial,c,s.batch⟩ z)
  (lhsBack z, {k with c := flip r w k.c})
def newTerms (s : Sizes) (w c : Nat) (r : Bool) (y : Four) :=
  (List.range s.spatial).map (newPair s w c r y)
def eval {l k : Four} (x : Arr l) (v : Arr k) (pairs : List (Four × Four)) :=
  (pairs.map fun (i,j) => read x i * read v j).foldl (·+·) 0
def packed (s z : Four) := ((z.a*s.b+z.b)*s.c+z.c)*s.d+z.d
def Goal := ∀ (s : Sizes) (w c : Nat), Legal s → 1<w → win s.spatial w=1 →
  s.spatial=w ∧ s.batches=1 ∧ ∀ (r rc : Bool) (y : Four), Fits y (out s w c) →
  packed (out s w c) y = (y.a*c+y.c)*s.batch+y.d ∧
  oldTerms s w r rc y = newTerms s w c r y ∧
  (∀ t < s.spatial, Fits (newPair s w c r y t).1 (input s c) ∧
    Fits (newPair s w c r y t).2 (kernel s w)) ∧
  ∀ (x : Arr (input s c)) (v : Arr (kernel s w)),
    eval x v (oldTerms s w r rc y) = eval x v (newTerms s w c r y)
end RevisedBenchmark.ConvMixedSpatial
