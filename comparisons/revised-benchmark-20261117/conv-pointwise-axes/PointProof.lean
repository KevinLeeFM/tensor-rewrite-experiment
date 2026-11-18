module
public import PointSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.ConvPointAxes

theorem oneBatch (s : Sizes) (h : Legal s) : s.batches = 1 := by
  obtain ⟨f,b,exclusive,dvd,_⟩ := h
  by_cases large : 1 < s.batches
  · have only : s.groups = 1 := by omega
    rw [only, Nat.mod_eq_of_lt large] at dvd
    contradiction
  · omega

private theorem transport (source result : Order) (b f s : Nat) :
    inverseRead source result (place result b f s) = place source b f s := by
  funext p
  simp [inverseRead, permutation, place, result.role_slot]

private theorem decode (o : Order) (y : Coord) :
    place o (y (o.slot .batch)) (y (o.slot .feature)) (y (o.slot .space)) = y := by
  funext p
  have hp := o.slot_role p
  cases e : o.role p <;> simp_all [place]

/-- Operand reshape retains equal-size axes in their physical order, exactly
the same increasing axis numbers that the broadcast uses on its target. -/
def retained (src dst : Coord) (ps : List (Fin 3)) := ps.filter fun p => src p == dst p

/-- Unpack the squeezed tensor coordinate back into the old tensor. For each
deleted singleton the only valid inserted coordinate is zero. -/
def unsqueeze (src dst : Coord) : List (Fin 3) → List Nat → List Nat
  | [], _ => []
  | p::ps, compact =>
    if src p = dst p then compact.headD 0 :: unsqueeze src dst ps compact.tail
    else 0 :: unsqueeze src dst ps compact

theorem broadcastSequence (src dst y : Coord) (ps : List (Fin 3)) :
    unsqueeze src dst ps ((retained src dst ps).map y) = ps.map (broadcastRead src dst y) := by
  induction ps with
  | nil => rfl
  | cons p ps ih =>
    by_cases eq : src p = dst p <;> simp_all [unsqueeze,retained,broadcastRead]

theorem verified : Goal := by
  intro s h
  have bg := oneBatch s h
  have g := h.1
  have unit := Nat.div_self g
  refine ⟨bg, ?_⟩
  intro l k o
  have outEq : outShape s o = lhsShape s o := by simp [outShape,lhsShape,bg]
  refine ⟨fun p => by simp [permutation,o.role_slot,l.slot_role,k.slot_role],outEq,?_,?_⟩
  · intro p
    simp only [permutation, lhsShape, rhsShape, place, l.role_slot, k.role_slot, true_and]
    cases o.role p <;> simp
  · intro y legal
    have bounds := legal
    rw [outEq] at bounds
    have b := bounds (o.slot .batch)
    have z := bounds (o.slot .feature)
    have t := bounds (o.slot .space)
    simp only [lhsShape, place, o.role_slot] at b z t
    have groupZero := Nat.div_eq_of_lt z
    have readL : oldL s l o y 0 0 = inverseRead l o y := by
      rw [← decode o y, transport]
      simp [oldL, bg, unit, place, o.role_slot, groupZero]
    have shrink : broadcastRead (place o 1 s.groups 1) (lhsShape s o) y =
        place o 0 (y (o.slot .feature)) 0 := by
      funext p
      have hp := o.slot_role p
      cases e : o.role p <;> simp only [e] at hp <;>
        simp [broadcastRead,lhsShape,place,← hp,o.role_slot] <;> omega
    have readK : oldK k o y 0 0 = newK s k o y := by
      simp [oldK,newK,shrink,transport]
    refine ⟨?_,?_,readL,readK,?_⟩
    · intro p
      rw [← decode o y, transport]
      cases e : l.role p <;> simp [lhsShape,place,e,b,z,t]
    · intro p
      rw [← readK]
      cases e : k.role p <;> simp [rhsShape,oldK,place,e,z]
    · intro x w
      simp [doConv,product,unit,readL,readK]
/-- Apply the retained-axis construction specifically to the transposed kernel. -/
theorem physicalKernelSequence (s : Sizes) (k o : Order) (y : Coord) :
    let src := place o 1 s.groups 1
    let dst := lhsShape s o
    let ps := List.finRange 3
    unsqueeze src dst ps ((retained src dst ps).map y) =
      ps.map (fun i => newK s k o y (permutation k o i)) := by
  simp only [newK,inverseRead,permutation,k.role_slot,o.slot_role]
  exact broadcastSequence _ _ _ _
#print axioms physicalKernelSequence
#print axioms verified
end RevisedBenchmark.ConvPointAxes
