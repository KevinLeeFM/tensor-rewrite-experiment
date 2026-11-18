module
public import Std
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.AdjacentScan

/-- Identity of the source instruction plus starts of the non-concat crop on
each side of the concat axis, in logical axis order. -/
structure Key where
  src : Nat
  pre : List Nat
  post : List Nat
deriving DecidableEq, Repr

/-- Only unit-stride slices enter the slice constructor. Opaque operands include
all other slice strides and all non-slice instructions, as already evaluated. -/
inductive Block where
  | slice (key : Key) (start width : Nat)
  | opaque (id width : Nat)
deriving DecidableEq, Repr

def width : Block → Nat
  | .slice _ _ w | .opaque _ w => w

/-- Carry the first start; use the last slice's exclusive limit minus it. -/
def merge : Block → Block → Option Block
  | .slice a s w, .slice b t v =>
    if a = b ∧ s+w = t then some (.slice a s ((t+v)-s)) else none
  | _, _ => none

/-- Left-to-right pending run. A guard failure flushes it before starting a
new run; no matching operand is skipped to merge non-neighbors. -/
def run (pending : Block) : List Block → List Block
  | [] => [pending]
  | b::tail => match merge pending b with
    | some joined => run joined tail
    | none => pending :: run b tail
def scan : List Block → List Block
  | [] => []
  | b::t => run b t

def coords : List Nat → List (List Nat)
  | [] => [[]]
  | n::ds => (List.range n).flatMap fun i => (coords ds).map (i :: ·)

abbrev Reader (α : Type) := Nat → List Nat → Nat → List Nat → α

/-- For each outer coordinate, enumerate concat-axis positions followed by
all inner coordinates. Slice values come from the source at physical origins. -/
def row {α : Type} (src opaque : Reader α) (outer post : List Nat) : Block → List α
  | .slice k s w => (List.range' s w).flatMap fun i => (coords post).map fun inner =>
    src k.src (List.zipWith Nat.add k.pre outer) i (List.zipWith Nat.add k.post inner)
  | .opaque id w => (List.range w).flatMap fun i => (coords post).map (opaque id outer i)

def packed {α : Type} (src opaque : Reader α) (pre post : List Nat) (bs : List Block) :=
  (coords pre).flatMap fun outer => bs.flatMap (row src opaque outer post)

/-- Arbitrary static pre/post frame, empty extents and ranks permitted. The
legal XLA subdomain has crop origins of matching rank and bounded slices.
Total reads extend legal tensors; the stronger equality needs no such premise. -/
def Goal := ∀ (bs : List Block),
  ((scan bs).map width).sum = (bs.map width).sum ∧
  ∀ (α : Type) (src opaque : Reader α) (pre post : List Nat),
    packed src opaque pre post (scan bs) = packed src opaque pre post bs
end RevisedBenchmark.AdjacentScan
