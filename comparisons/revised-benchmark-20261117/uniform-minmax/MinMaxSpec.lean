import ExchangeSpec
set_option autoImplicit false
namespace RevisedBenchmark.MinMax
open Exchange

/-- Bit-order extrema after decoding the fixed integral type into mathematical integers. -/
inductive Kind where | minimum | maximum deriving DecidableEq
def combine : Kind → Int → Int → Int
  | .minimum => min
  | .maximum => max

/-- The first listed participant contributes the seed. The other g participants follow in order. -/
def reduceAt {g : Nat} {I : Type} (op : Kind) (x : Fin (g+1) → I → Int) (i : I) : Int :=
  (List.finRange g).foldl (fun a r => combine op a (x r.succ i)) (x 0 i)

/-- Both operations read actual participant arrays. Reduce-scatter selects the receiver's block. -/
def allReduce {g : Nat} {I : Type} (op : Kind) (x : Fin (g+1) → I → Int) :
    Fin (g+1) → I → Int := fun _ i => reduceAt op x i
def reduceScatter {g k : Nat} {C : Type} (op : Kind)
    (x : Fin (g+1) → Fin ((g+1)*k) × C → Int) :
    Fin (g+1) → Fin k × C → Int := fun r i => reduceAt op x (slot r i.1, i.2)

def Case (op : Kind) : Prop :=
  (∀ (g : Nat) (I : Type) (v : Int),
      allReduce (g := g) (I := I) op (fun _ _ => v) = fun _ _ => v) ∧
  (∀ (g k : Nat) (C : Type) (v : Int),
      reduceScatter (g := g) (k := k) (C := C) op (fun _ _ => v) = fun _ _ => v)
end RevisedBenchmark.MinMax
