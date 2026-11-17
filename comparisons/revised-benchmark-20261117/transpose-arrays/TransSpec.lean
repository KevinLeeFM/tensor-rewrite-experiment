import TensorRewrite.Pilot.PermutationLoopLemmas
import TensorRewrite.Pilot.Transpose
import TensorRewrite.Pilot.IndexMaps
set_option autoImplicit false
namespace RevisedBenchmark.TransArrays
open TensorRewrite.Pilot Tensor
def inverse {r : Nat} (p : AxisPermutation r) : AxisPermutation r :=
  ⟨p.inputToOutput,p.outputToInput,p.input_output,p.output_input⟩

def SortedForward : Prop := ∀ {r : Nat} (s t : Shape r) (p : AxisPermutation r)
    (h : ∀ i, t (p.inputToOutput i) = s i)
    (ordered : ∀ i j, i < j → p.outputToInput i ≤ p.outputToInput j),
    ∃ same : t = s, ∀ (α : Type) (x : Tensor s α), transpose p h x = same.symm ▸ x

def Nested : Prop := ∀ {r : Nat} (s t u : Shape r) (p q : AxisPermutation r)
    (h : ∀ i, t (p.inputToOutput i) = s i) (g : ∀ i, u (q.inputToOutput i) = t i),
    AxisArray.composeLoop (AxisArray.ofPermutation p) (AxisArray.ofPermutation q) =
      (AxisArray.ofPermutation (p.comp q)).toArray ∧
    ∀ (α : Type) (x : Tensor s α), transpose q g (transpose p h x) =
      transpose (p.comp q) (fun i => (g _).trans (h i)) x

def BroadcastTranspose : Prop := ∀ {r : Nat} (s t : Shape r) (a : IndexMaps.BroadcastAxes r r)
    (p : AxisPermutation r) (legal : ∀ i, a.decode i = p.outputToInput i)
    (h : ∀ i, s i = t (a.decode i)) (α : Type) (x : Tensor s α),
    reindex (IndexMaps.broadcastIndex a h) x =
      transpose (inverse p) (fun i => by change t (p.outputToInput i) = s i; rw [← legal i]; exact (h i).symm) x
end RevisedBenchmark.TransArrays
