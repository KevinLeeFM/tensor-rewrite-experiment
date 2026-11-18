module
public import MixedSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.ConvMixedSpatial
open ConvPointAxes

theorem verified : Goal := by
  intro s w c legal hw hwin
  have size : s.spatial=w := by unfold win at hwin; omega
  have batches := oneBatch s legal
  have channel := Nat.div_self legal.1
  have carried : win c 1 = c := by unfold win; omega
  refine ⟨size,batches,?_⟩
  intro r rc y hy
  obtain ⟨hf,ht,hc,hb⟩ := hy
  simp only [out, hwin, carried, batches, Nat.div_one] at hf ht hc hb
  have zero : y.b = 0 := by omega
  have grp := Nat.div_eq_of_lt hf
  have bc : (if 1=c then y.c else 0) = 0 := by split <;> omega
  have bb : (if 1=s.batch then y.d else 0) = 0 := by split <;> omega
  have newRead (t : Nat) : newPair s w c r y t =
      (⟨t,y.d,y.c,y.a⟩,⟨0,y.a,flip r w t,0⟩) := by
    simp [newPair,lhsBack,kerBack,broadcast,size,bb,bc]
  have reads : oldTerms s w r rc y = newTerms s w c r y := by
    simp only [oldTerms, newTerms, channel, List.range_one, List.map_cons, List.map_nil,
      List.flatMap_cons, List.flatMap_nil, List.append_nil, size]
    have mapOne (xs : List Nat) (f : Nat → Four × Four) : xs.flatMap (fun t => [f t]) = xs.map f := by
      induction xs with
      | nil => rfl
      | cons a l ih => simp [ih]
    rw [mapOne]
    apply List.map_congr_left
    intro t _
    rw [newRead]
    simp [oldPair,channel,batches,grp,zero,flip]
  refine ⟨by simp [packed,out,hwin,carried,batches,zero], reads, ?_, fun x v => congrArg (eval x v) reads⟩
  intro t ht'
  have flipLt : flip r w t < w := by unfold flip; split <;> omega
  rw [newRead]
  exact ⟨⟨ht',hb,hc,hf⟩,⟨Nat.zero_lt_one,hf,flipLt,Nat.zero_lt_one⟩⟩
#print axioms verified
end RevisedBenchmark.ConvMixedSpatial
