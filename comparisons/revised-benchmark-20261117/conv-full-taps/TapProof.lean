module
public import TapSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.ConvFullTaps
open ConvPointAxes

private theorem slotEq (o : Order) (a b : Role) : o.slot a = o.slot b ↔ a=b :=
  ⟨fun h => by simpa [o.role_slot] using congrArg o.role h, congrArg _⟩

private theorem shrinkPack (o : Order) (s : Sizes) (w : Nat) (y : Coord)
    (bg : s.batches = 1) (out : win s.spatial w = 1) (zero : y (o.slot .space) = 0)
    (acc : Nat) (ps : List (Fin 3)) :
    pack (finalShape s w o) y acc ps =
      pack (lhsShape s o) y acc (ps.filter (fun p => p != o.slot .space)) := by
  induction ps generalizing acc with
  | nil => rfl
  | cons p t ih =>
    have hp := o.slot_role p
    cases e : o.role p <;> simp only [e] at hp <;> subst p <;>
      simp [pack,finalShape,lhsShape,place,slotEq,o.role_slot,bg,out,zero] at ih ⊢ <;>
      exact ih _

theorem verified : Goal := by
  intro s w h positive _ out
  obtain size : s.spatial = w := by unfold win at out; omega
  have bg := oneBatch s h
  refine ⟨size,bg,?_⟩
  intro l k o rev y legal
  have b := legal (o.slot .batch)
  have f := legal (o.slot .feature)
  have z := legal (o.slot .space)
  simp only [finalShape, place, o.role_slot, bg, Nat.div_one, out] at b f z
  have zero : y (o.slot .space) = 0 := by omega
  have taps (t : Nat) (ht : t < s.spatial) :
      Fits (lhsShape s l) (inverseRead l o (insertTap o y t)) ∧
      Fits (kernelShape s w k) (newPair s w l k o rev y t).2 ∧
      (oldL s l o y t 0, oldK k o y (flipTap rev w t) 0) = newPair s w l k o rev y t := by
    let c := insertTap o y t
    have validC : Fits (outShape s o) c := by
      intro p
      have hp := o.slot_role p
      cases e : o.role p <;> simp only [e] at hp <;> subst p <;>
        simp [c,insertTap,outShape,place,o.role_slot,slotEq,bg,b,f,ht]
    obtain ⟨leftFit,_,leftIdx,_,_⟩ := (ConvPointAxes.verified s h).2 l k o |>.2.2.2 c validC
    have left : oldL s l o y t 0 = inverseRead l o c := by
      rw [← leftIdx]
      simp [oldL,c,insertTap,slotEq,zero]
    have raw : inverseRead k o (broadcastRead (kernelShape s w o) (lhsShape s o) c) =
        place k 0 (y (o.slot .feature)) t := by
      funext p
      have hp := k.slot_role p
      cases e : k.role p <;> simp only [e] at hp <;> subst p <;>
        simp [inverseRead,permutation,k.role_slot,o.role_slot,broadcastRead,kernelShape,
          lhsShape,place,c,insertTap,slotEq,size] <;> omega
    have right : (newPair s w l k o rev y t).2 = oldK k o y (flipTap rev w t) 0 := by
      change reversedRead k rev w (inverseRead k o (broadcastRead _ _ c)) = _
      rw [raw]
      funext p
      have hp := k.slot_role p
      cases e : k.role p <;> simp only [e] at hp <;> subst p <;>
        simp [reversedRead,oldK,place,k.role_slot,slotEq]
    refine ⟨leftFit,?_,Prod.ext left right.symm⟩
    intro p
    rw [right]
    have smaller : flipTap rev w t < w := by cases rev <;> simp [flipTap] <;> omega
    cases e : k.role p <;> simp [oldK,kernelShape,place,e,f,smaller]
  have terms : oldTerms s w l k o rev y = newTerms s w l k o rev y := by
    simp only [oldTerms,newTerms,Nat.div_self h.1,List.range_one,List.map_cons,List.map_nil,size]
    have singleton {A B : Type} (xs : List A) (f : A → B) :
        xs.flatMap (fun a => [f a]) = xs.map f := by
      induction xs <;> simp_all
    rw [singleton]
    apply List.map_congr_left
    intro t ht
    exact (taps t (by have := List.mem_range.mp ht; omega)).2.2
  exact ⟨shrinkPack o s w y bg out zero 0 _,terms,fun t ht => ⟨(taps t ht).1,(taps t ht).2.1⟩,
    fun x kernel => by rw [terms]⟩
#print axioms verified
end RevisedBenchmark.ConvFullTaps
