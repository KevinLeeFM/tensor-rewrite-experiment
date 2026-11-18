import Std
namespace RevisedBenchmark.ConvU8

abbrev Byte := BitVec 8
def convByte (a w : Byte) : Byte :=
  let acc := (0#64) + (a.zeroExtend 64) * (w.zeroExtend 64)
  BitVec.ofNat 8 (min acc.toNat 255)

def conv {g : Nat} (x w : Fin g → Byte) (out : Fin g) := convByte (x out) (w out)
def product {g : Nat} (x w : Fin g → Byte) (out : Fin g) := x out * w out

def Goal := ∀ (g : Nat), 1 < g → ∀ (x w : Fin g → Byte), conv x w = product x w
end RevisedBenchmark.ConvU8
