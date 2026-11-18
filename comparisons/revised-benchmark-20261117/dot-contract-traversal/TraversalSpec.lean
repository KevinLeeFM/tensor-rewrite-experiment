import RadixSpec
namespace RevisedBenchmark.DotTraversal
open RevisedBenchmark.RadixIota (r32)

def flip (k : Fin 4) : Fin 4 := ⟨k.val % 2 * 2 + k.val / 2, by omega⟩
abbrev Data := Fin 4 → Nat
def mulAt (constantFirst : Bool) (x w : Nat) :=
  if constantFirst then r32 (w*x) else r32 (x*w)
def dot (term : Fin 4 → Nat) :=
  (List.finRange 4).foldl (fun acc k => r32 (acc + term k)) 0
def old (side : Bool) (x w : Data) := dot (fun k => mulAt side (x (flip k)) (w k))
def newDot (side : Bool) (x w : Data) := dot (fun k => mulAt side (x k) (w (flip k)))
def Goal (side : Bool) := ∀ x w, (∀ i, x i ≤ 2^24) → (∀ i, w i ≤ 2) →
  old side x w = newDot side x w
end RevisedBenchmark.DotTraversal
