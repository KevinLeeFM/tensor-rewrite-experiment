import GatherEmptySpec
namespace RevisedBenchmark.GatherEmpty

private theorem zeroProd (ns : List Nat) : ns.prod = 0 ↔ 0 ∈ ns := by
  induction ns with
  | nil => simp
  | cons n t ih => simp [List.prod_cons, Nat.mul_eq_zero, ih, eq_comm]

private theorem interleaveZero {w b o : List Nat} (h : Interleave w b o) :
    0 ∈ o ↔ 0 ∈ w ∨ 0 ∈ b := by
  induction h with
  | nil => simp
  | win n _ ih => simp only [List.mem_cons, ih, or_assoc]
  | idx n _ ih => simp only [List.mem_cons, ih, or_left_comm]

private theorem uniform (n : Nat) (z : BitVec 8) :
    (List.range n).map (fun _ => z) = List.replicate n z := by
  have aux (xs : List Nat) : xs.map (fun _ => z) = List.replicate xs.length z := by
    induction xs with
    | nil => rfl
    | cons a t ih => simp [List.replicate_succ, ih]
  simpa using aux (List.range n)

private theorem bytes (out : List Nat) (z : BitVec 8) :
    evaluator out = replacement out z ↔ out.prod = 0 ∨ z = 0 := by
  unfold evaluator replacement
  rw [uniform]
  cases n : out.prod with
  | zero => simp
  | succ k =>
    constructor
    · intro h
      have h' := congrArg List.head? h
      simp only [List.replicate_succ, List.head?_cons, Option.some.injEq] at h'
      exact Or.inr h'.symm
    · rintro (h | rfl)
      · omega
      · rfl

theorem verified : Goal := by
  intro xs batch out legal _ order
  have classification := (zeroProd out).trans (interleaveZero order)
  refine ⟨classification, ?_, bytes out, (bytes out 0).2 (Or.inr rfl)⟩
  intro nonempty a mem zero
  have excl := mt classification.mpr nonempty
  have fit := (legal a mem).1
  cases h : a.role with
  | collapsed => rfl
  | window =>
    exfalso
    apply excl
    apply Or.inl
    exact List.mem_map.mpr ⟨a, List.mem_filter.mpr ⟨mem, by simp [h]⟩, by omega⟩
  | batched =>
    exfalso
    apply excl
    exact Or.inr (zero ▸ (legal a mem).2.2 h)
#print axioms verified
end RevisedBenchmark.GatherEmpty
