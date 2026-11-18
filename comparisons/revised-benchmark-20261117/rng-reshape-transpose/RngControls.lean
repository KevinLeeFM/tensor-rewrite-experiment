import RngProof
namespace RevisedBenchmark.RandomShape
def w (b : Bool) := if b then 3 else 1
def b (i : Fin 3) (j : Fin 2) := i.val == 2 || j.val == 1
example : mass 2 3 w (fun i j => b j i) = 81 ∧ mass 3 2 w b = 81 := by decide
example : total 2 3 w = 4096 := by decide
example : mass 0 3 w (fun i _ => Fin.elim0 i) = 1 := by decide
example : oldReshape id 3 2 1 1 = 3 := by decide
/-- Equiprobable horizontal-stripe image and complement: every coordinate
has balanced marginal, yet the transposed support consists of vertical stripes. -/
def stripe (flip : Bool) (i _ : Fin 2) := (i.val == 1) != flip
example : stripe false 1 0 ≠ stripe false 0 1 := by decide
example : stripe false 0 0 ≠ stripe true 0 0 := by decide
example : (∀ i j, stripe false i j = stripe false j i) = False := by decide
example : (∀ i j, stripe true i j = stripe false j i) = False := by decide
#check (transposeLaw : Law)
#check (reshapeStream : Reshape)
#check (differentSeedObservation : ¬SameSeedTranspose)
end RevisedBenchmark.RandomShape
