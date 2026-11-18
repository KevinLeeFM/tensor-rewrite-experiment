import ExpandProof
namespace RevisedBenchmark.SinkMixed
def s2 (i : Fin 2) := if i = 0 then 1 else 3
def t2 (i : Fin 2) := if i = 0 then 5 else 3
def legal (i : Fin 2) : s2 i = 1 ∨ t2 i = s2 i := by
  by_cases h : i = 0 <;> simp [s2, t2, h]
def out2 (i : Fin 2) : Fin (t2 i) :=
  if h : i = 0 then ⟨4, by simp [t2, h]⟩ else ⟨2, by simp [t2, h]⟩
example : (expandProject id legal out2 0).val = 0 := by decide
example : (expandProject id legal out2 1).val = 2 := by decide
example : (expandProject id legal out2 0).val ≠ (out2 0).val := by decide
#check (expanded : ExpandedGoal)
end RevisedBenchmark.SinkMixed
