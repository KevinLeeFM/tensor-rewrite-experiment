import Std
namespace RevisedBenchmark.ClampGuard
def clipped (lo x hi : Int) := min (max lo x) hi
def old (reverse : Bool) (lo x hi : Int) :=
  if reverse then max (clipped lo x hi) lo else max lo (clipped lo x hi)
def Goal := ∀ (I : Type) (lo x hi : I → Int) (reverse : Bool),
  (fun i => old reverse (lo i) (x i) (hi i)) = (fun i => clipped (lo i) (x i) (hi i))
def Domain := ∀ (I : Type) (lo x hi : I → Int) (reverse : Bool),
  ((fun i => old reverse (lo i) (x i) (hi i)) = (fun i => clipped (lo i) (x i) (hi i))) ↔
  ∀ i, lo i ≤ hi i
end RevisedBenchmark.ClampGuard
