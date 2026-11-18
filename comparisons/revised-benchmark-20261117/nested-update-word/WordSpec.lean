import Std

namespace RevisedBenchmark.NestedUpdateWord

def evaluatorStart (limit : Nat) (index : BitVec 64) : Nat :=
  min limit index.toInt.toNat

def typedStart (limit : Nat) (index : BitVec 64) : BitVec 64 :=
  BitVec.ofNat 64 (min limit index.toNat)

/-- Read a bounded window of a rank-one array. -/
def readWindow {n : Nat} (len : Nat) (fits : len ≤ n) (base : Fin n → Nat)
    (index : BitVec 64) (pos : Fin len) :=
  base ⟨evaluatorStart (n-len) index + pos.val, by
    have h := Nat.min_le_left (n-len) index.toInt.toNat
    have hp := pos.isLt
    unfold evaluatorStart
    omega⟩

def install {n m : Nat} (base : Fin n → Nat) (data : Fin m → Nat)
    (index : BitVec 64) (pos : Fin n) :=
  let start := evaluatorStart (n-m) index
  if h : start ≤ pos.val ∧ pos.val-start < m then data ⟨_,h.2⟩ else base pos

def Case := ∀ (base : Fin 10 → Nat) (patch : Fin 2 → Nat) (outer inner : BitVec 64),
  install base (install (readWindow 6 (by decide) base outer) patch inner) outer =
  install base patch (typedStart 4 outer + typedStart 4 inner)

end RevisedBenchmark.NestedUpdateWord
