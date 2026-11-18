import PipelineSpec
import FoldProof
namespace RevisedBenchmark.PrefixPipeline

theorem uniform {n : Nat} (ss : List (Stage n)) (v : Int) (i : Fin n) :
    data ss v i = scalar ss v := by
  induction ss generalizing i with
  | nil => rfl
  | cons s ss ih =>
    cases s with
    | view p => simpa [data,scalar,casts] using ih (p i)
    | cast c =>
      simp [data,scalar,casts, List.foldl_append, ih,scalar]

theorem verified : Goal := by
  intro t n _ ss v r
  simp only [old,newValue,uniform, List.map_const',List.length_finRange,
    MixedTapCount.repeatSum,BitVec.ofNat_add]
  rw [BitVec.mul_comm]
  cases t <;> simp [width] <;> exact BitVec.zero_add _
#print axioms verified
end RevisedBenchmark.PrefixPipeline
