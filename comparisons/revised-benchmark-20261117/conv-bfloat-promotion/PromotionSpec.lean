import Std
namespace RevisedBenchmark.ConvPromotion

/-- BF16 round-to-nearest-even for small nonnegative integer-valued inputs. -/
def bf (n : Nat) : Nat :=
  let step := 2 ^ (n.log2 - 7)
  let q := n / step
  let rem := n % step
  (q + if 2*rem > step ∨ (2*rem = step ∧ q%2 = 1) then 1 else 0) * step

abbrev Input := Fin 2 → Fin 512
def sample (x : Input) (o : Fin 3) : Nat :=
  if o.val = 0 then (x 0).val else if o.val = 2 then (x 1).val else 0

/-- For a one-tap kernel, the only live F32 accumulation is 0+x*w. -/
def original (x : Input) (w : Fin 16) (o : Fin 3) := bf (0 + bf (sample x o) * w.val)
def promoted (x : Input) (w : Fin 16) (o : Fin 3) := bf (0 + sample x o * w.val)
def Preserves := ∀ (x : Input) (w : Fin 16) (o : Fin 3),
  original x w o = promoted x w o
end RevisedBenchmark.ConvPromotion
