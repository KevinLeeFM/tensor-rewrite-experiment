import Std
set_option autoImplicit false
namespace RevisedBenchmark.IotaRead

abbrev Word := BitVec 32
def decode (signed : Bool) (x : Word) : Int := if signed then x.toInt else x.toNat
def signCap (signed : Bool) : Nat := if signed then 2147483647 else 4294967295
def convert (fromSigned toSigned : Bool) (x : Word) : Word :=
  if fromSigned = toSigned then x else if fromSigned then BitVec.ofInt 32 x.toInt else BitVec.ofNat 32 x.toNat
def scale (m : Option Word) (x : Word) : Word := match m with | some k => x * k | none => x

/-- Address of a legal one-element rank-one slice. -/
def original (n : Nat) (valid : 0 < n) (signed : Bool) (a : Word)
    (m : Option Word) : Fin 1 → Word :=
  let start := min (decode signed a).toNat (n-1)
  let addr : Fin n := ⟨start, Nat.lt_of_le_of_lt (Nat.min_le_right _ _) (by omega)⟩
  let operand : Fin n → Word := fun i => scale m (BitVec.ofNat 32 i.val)
  fun _ => operand addr

/-- Typed clamp at the original index width, convert before multiply, then reshape scalar to [1]. -/
def replacement (n : Nat) (indexSigned elementSigned : Bool) (a : Word)
    (m : Option Word) : Fin 1 → Word :=
  let high : Word := BitVec.ofNat 32 (min (n-1) (signCap indexSigned))
  let clamped := if decode indexSigned a < 0 then (0 : Word) else
    if decode indexSigned high < decode indexSigned a then high else a
  fun _ => scale m (convert indexSigned elementSigned clamped)

def Plain : Prop := ∀ (n : Nat) (valid : 0 < n) (indexSigned elementSigned : Bool) (a : Word),
  original n valid indexSigned a none = replacement n indexSigned elementSigned a none

def Scaled : Prop := ∀ (n : Nat) (valid : 0 < n) (indexSigned elementSigned : Bool) (a k : Word),
  original n valid indexSigned a (some k) = replacement n indexSigned elementSigned a (some k)
end RevisedBenchmark.IotaRead
