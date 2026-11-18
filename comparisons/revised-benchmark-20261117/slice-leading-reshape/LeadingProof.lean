import LeadingSpec
set_option autoImplicit false
namespace RevisedBenchmark.LeadingSlice

private theorem decode (ns : List Nat) (p k : Nat) (b : Box) (h : build ns p k = some b) :
    size b = k ∧ ∀ j < k, readPos b j = p+j := by
  induction ns generalizing p k b with
  | nil =>
    simp only [build] at h
    split at h
    · rename_i g
      obtain ⟨rfl,rfl⟩ := g
      cases h
      exact ⟨rfl, fun j hj => by simp [readPos]; omega⟩
    · contradiction
  | cons n ns ih =>
    simp only [build] at h
    split at h
    · contradiction
    · rename_i nz
      split at h
      · split at h
        · rename_i align
          obtain ⟨outer, ok, rfl⟩ := Option.map_eq_some_iff.mp h
          obtain ⟨width, addr⟩ := ih _ _ _ ok
          have kw := Nat.mod_add_div k n
          rw [align.1, Nat.zero_add] at kw
          have pw := Nat.mod_add_div p n
          rw [align.2, Nat.zero_add] at pw
          refine ⟨by simp [size,width,kw], ?_⟩
          intro j hj
          have small : j/n < k/n := (Nat.div_lt_iff_lt_mul (by omega)).2
            (by rwa [Nat.mul_comm,kw])
          simp only [readPos, Nat.zero_add, addr _ small, Nat.mul_add, pw]
          have rem := Nat.mod_add_div j n
          omega
        · contradiction
      · split at h
        · obtain ⟨outer,ok,rfl⟩ := Option.map_eq_some_iff.mp h
          obtain ⟨width,addr⟩ := ih _ _ _ ok
          refine ⟨by simp [size,width], ?_⟩
          intro j hj
          simp only [readPos, Nat.mod_eq_of_lt hj, Nat.div_eq_of_lt hj, addr 0 (by decide), Nat.add_zero]
          have rem := Nat.mod_add_div p n
          omega
        · contradiction

/-- Each generated source Slice axis has the matching extent and an in-range exclusive limit. -/
def legal : List Nat → Box → Prop
  | [], .scalar => True
  | n :: ds, .axis extent start width outer =>
    extent = n ∧ start + width ≤ n ∧ legal ds outer
  | _, _ => False

theorem generatedLegal (ds : List Nat) (p k : Nat) (b : Box) (ok : build ds p k = some b) :
    legal ds b := by
  induction ds generalizing p k b with
  | nil =>
    simp only [build] at ok
    split at ok
    · cases ok; trivial
    · contradiction
  | cons n ds ih =>
    simp only [build] at ok
    split at ok
    · contradiction
    · split at ok <;> split at ok
      · obtain ⟨outer,h,rfl⟩ := Option.map_eq_some_iff.mp ok
        exact ⟨rfl, by omega, ih _ _ _ h⟩
      · contradiction
      · obtain ⟨outer,h,rfl⟩ := Option.map_eq_some_iff.mp ok
        exact ⟨rfl, by omega, ih _ _ _ h⟩
      · contradiction

theorem verified : Case := by
  intro ns tail lead s e b count hse hel ok
  obtain ⟨width,addr⟩ := decode _ _ _ _ ok
  refine ⟨width, ?_⟩
  intro α x j
  rw [addr _ j.isLt, count]
  have small := j.isLt
  have diff := Nat.sub_mul e s tail.prod
  have se := Nat.mul_le_mul_right tail.prod hse
  have el := Nat.mul_le_mul_right tail.prod hel
  exact ⟨by omega,rfl⟩
example : Case := verified
#print axioms verified
#print axioms generatedLegal
end RevisedBenchmark.LeadingSlice
