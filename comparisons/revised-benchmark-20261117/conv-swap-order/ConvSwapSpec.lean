import RadixSpec
set_option autoImplicit false
namespace RevisedBenchmark.ConvSwapOrder
open RevisedBenchmark.RadixIota (r32)

structure W where
  input : Nat
  width : Nat
  low : Int
  high : Int
  reverseKernel : Bool
deriving DecidableEq, Repr

def extent (w : W) := ((w.input : Int)+w.low+w.high-w.width+1).toNat
def before : W := ⟨3,4,0,1,false⟩
def after : W := ⟨before.width,before.input,(before.input:Int)+before.low-before.width,
  (before.input:Int)+before.high-before.width,true⟩

def mirror {n : Nat} (i : Fin n) : Fin n := ⟨n-1-i.val,by have := i.isLt; omega⟩

def pairs (w : W) (out : Fin (extent w)) : List (Fin w.input × Fin w.width) :=
  (List.finRange w.width).filterMap fun tap =>
    let pos := ((out.val+tap.val : Nat):Int)-w.low
    if h : 0 ≤ pos ∧ pos.toNat < w.input then
      some (⟨pos.toNat,h.2⟩,if w.reverseKernel then mirror tap else tap)
    else none

def terms (w : W) (o : Fin (extent w)) (x : Fin w.input → Nat) (k : Fin w.width → Nat) :=
  (pairs w o).map fun (i,j) => r32 (x i * k j)

def sum32 (xs : List Nat) := xs.foldl (fun acc x => r32 (acc+x)) 0
def original (x : Fin 3 → Nat) (k : Fin 4 → Nat) := sum32 (terms before ⟨0,by decide⟩ x k)
def rewritten (x : Fin 3 → Nat) (k : Fin 4 → Nat) :=
  sum32 (terms after ⟨0,by decide⟩ (fun i => k (mirror i)) x)

def StrictCase := ∀ (x : Fin 3 → Nat) (k : Fin 4 → Nat),
  (∀ i, x i ≤ 2^24) → (∀ j, k j ≤ 2^24) → original x k = rewritten x k
end RevisedBenchmark.ConvSwapOrder
