import Std
namespace RevisedBenchmark.AbsIota

def original (k n : Nat) (C : Type) (i : Fin n) (_ : C) :=
  (BitVec.ofNat (k + 2) i.val).abs

def replacement (k n : Nat) (C : Type) (i : Fin n) (_ : C) :=
  BitVec.ofNat (k + 2) i.val

def Case : Prop := ∀ (k n : Nat) (C : Type),
  original k n C = replacement k n C ↔ (C → False) ∨ n ≤ 2^(k+1) + 1

end RevisedBenchmark.AbsIota
