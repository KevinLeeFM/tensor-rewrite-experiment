import Std
namespace RevisedBenchmark.CopyChain

/-- A static dense layout bijects logical coordinates with physical element addresses. -/
structure Layout (I : Type) (n : Nat) where
  address : I → Fin n
  coordinate : Fin n → I
  decode_encode : ∀ i, coordinate (address i) = i
  encode_decode : ∀ a, address (coordinate a) = a

/-- Fill each destination address by reading the same logical coordinate in the source. -/
def copy {I α : Type} {n : Nat} (src dst : Layout I n) (mem : Fin n → α) : Fin n → α :=
  fun a => mem (src.address (dst.coordinate a))

def Goal := ∀ (I α : Type) (n : Nat) (src mid dst : Layout I n) (mem : Fin n → α),
  copy mid dst (copy src mid mem) = copy src dst mem ∧
  copy mid src (copy src mid mem) = mem
end RevisedBenchmark.CopyChain
