import Std
namespace RevisedBenchmark.NegatedReduction

/-- Sign bit of a binary32 zero; true denotes the negative encoding. -/
abbrev ZeroSign := Bool
def bits (s : ZeroSign) : BitVec 32 := if s then 0x80000000#32 else 0#32
def plus (a b : ZeroSign) : ZeroSign := a && b
def oldBits (seed : ZeroSign) (xs : List ZeroSign) :=
  bits ((xs.map Bool.not).foldl plus seed)
def newBits (seed : ZeroSign) (xs : List ZeroSign) :=
  bits (!xs.foldl plus seed)
def SeedIdentity (s : ZeroSign) := ∀ x, plus s x = x ∧ plus x s = x
def Preserves : Prop := ∀ s, SeedIdentity s → ∀ xs : List ZeroSign,
  2 ≤ xs.length → oldBits s xs = newBits s xs
end RevisedBenchmark.NegatedReduction
