import Std
set_option autoImplicit false
namespace RevisedBenchmark.ChunkHoist

/-- Major-to-minor digits as (radix, value). -/
abbrev Digit := Nat × Nat
def volume (ds : List Digit) := (ds.map Prod.fst).prod
def pack : List Digit → Nat
  | [] => 0
  | (w,v)::ds => v * volume ds + pack ds

/-- Decode a chunk position into the original consecutive transpose-output axes.
The quotient is the major digit; the remaining flat position is its remainder. -/
def expand : List Nat → Nat → List Digit
  | [], _ => []
  | w::ws, v => (w,v/ws.prod) :: expand ws (v%ws.prod)

structure Order (m : Nat) where
  toInput : Fin m → Fin m
  toOutput : Fin m → Fin m
  leftInv : ∀ k, toInput (toOutput k) = k
  rightInv : ∀ u, toOutput (toInput u) = u

/-- Blocks indexed in input-axis order. A permutation represents their actual order
in the transpose output. Each valid output coordinate selects a position in every chunk. -/
abbrev Index {m : Nat} (p : Order m) (blocks : Fin m → List Nat) :=
  (u : Fin m) → Fin (blocks (p.toInput u)).prod
def expanded {m : Nat} {p : Order m} {blocks : Fin m → List Nat}
    (i : Index p blocks) (u : Fin m) := expand (blocks (p.toInput u)) (i u).val
def outDigit {m : Nat} {p : Order m} {blocks : Fin m → List Nat}
    (i : Index p blocks) (u : Fin m) : Digit := ((blocks (p.toInput u)).prod,(i u).val)

def original {m : Nat} {p : Order m} {blocks : Fin m → List Nat} (i : Index p blocks) :=
  pack ((List.ofFn fun k => expanded i (p.toOutput k)).flatten)
def emitted {m : Nat} {p : Order m} {blocks : Fin m → List Nat} (i : Index p blocks) :=
  pack (List.ofFn fun k => ((blocks k).prod,(i (p.toOutput k)).val))

def Goal := ∀ (m : Nat) (p : Order m) (blocks : Fin m → List Nat),
  (∀ k, blocks k ≠ []) → ∀ (i : Index p blocks),
    -- Original reshape connects this output coordinate to these expanded transpose digits.
    pack ((List.ofFn (expanded i)).flatten) = pack (List.ofFn (outDigit i)) ∧
    -- Every original axis digit is in bounds and the two graph paths read the same source cell.
    (∀ u d, d ∈ expanded i u → d.2 < d.1) ∧
    original i = emitted i
end RevisedBenchmark.ChunkHoist
