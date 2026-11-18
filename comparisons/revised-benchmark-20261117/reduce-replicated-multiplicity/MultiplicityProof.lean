import MappedProof
import MultiplicitySpec
set_option autoImplicit false
namespace RevisedBenchmark.ReduceMultiplicity
open ReduceMapped

private def volume : List (Nat × Bool) → Nat
  | [] => 1
  | (n,true)::t => n * volume t
  | (_,false)::t => volume t

private theorem countBase (ds : List Axis) : volume (baseDims ds) = count ds := by
  induction ds with
  | nil => rfl
  | cons a t ih => cases a <;> simp [baseDims, count, volume, ih]

private theorem repeatBlock {α : Type} (xs : List Nat) (m : Nat) (x : α) :
    (xs.flatMap fun _ => List.replicate m x) = List.replicate (xs.length*m) x := by
  induction xs with
  | nil => simp
  | cons a t ih => simp [ih, List.replicate_append_replicate, Nat.succ_mul, Nat.add_comm]

private theorem eraseFiber (bs : List (Nat × Bool)) (out : List Nat)
    (legal : valid (outputShape bs) out) :
    (reads bs out).map (eraseReduced bs) = List.replicate (volume bs) out := by
  induction bs generalizing out with
  | nil => cases out <;> simp_all [reads, eraseReduced, volume, outputShape, valid]
  | cons d t ih =>
    obtain ⟨n,flag⟩ := d
    cases flag with
    | false =>
      cases out with
      | nil => contradiction
      | cons x xs =>
        have h : valid (outputShape t) xs := legal.2
        simp only [reads, List.map_map, eraseReduced, List.headD_cons, List.tail_cons, volume]
        simpa [List.map_map, Function.comp_def] using
          congrArg (List.map (x :: ·)) (ih xs h)
    | true =>
      have h : valid (outputShape t) out := legal
      simp [reads, List.map_flatMap, List.map_map, Function.comp_def,
        eraseReduced, ih out h, repeatBlock, volume]

/-- The product counts actual repetitions of the selected base coordinate. -/
theorem uniform (ds : List Axis) (out : List Nat) (h : valid (outputShape (dims ds)) out) :
    operandReads ds out = List.replicate (count ds) (newOut ds out) := by
  obtain ⟨legal, transport, _⟩ := ReduceMapped.verified ds out h
  simpa [operandReads, List.map_map, Function.comp_def, countBase] using
    (congrArg (List.map (eraseReduced (baseDims ds))) transport).trans (eraseFiber _ _ legal)

private theorem sumCopies (n : Nat) (value seed : Int) :
    (List.replicate n value).foldl (·+·) seed = seed + value * (n : Int) := by
  induction n generalizing seed with
  | zero => simp
  | succ n ih => simp [List.replicate_succ, ih, Int.mul_add, Int.add_assoc, Int.add_comm,
      Int.add_left_comm]

theorem exactInt : IntCase := by
  intro ds out h x
  rw [uniform ds out h, List.map_replicate, sumCopies]

/-- Six repetitions, with a nontrivial surviving replicated axis and a
surviving mapped axis of extent two. The operand varies across that axis. -/
def witness : List Axis := [.reduced 2, .added 4, .kept 2, .reduced 3]
def values (coord : List Nat) : Nat := if coord = [1] then 4194305 else 1

theorem refuted : ¬ FloatCase := by
  intro all
  have edge := all witness [3,1] (by change 3 < 4 ∧ 1 < 2 ∧ True; decide)
    (by decide) (by decide) values (by intro c; unfold values; split <;> decide)
  revert edge
  decide

#print axioms exactInt
#print axioms refuted
end RevisedBenchmark.ReduceMultiplicity
