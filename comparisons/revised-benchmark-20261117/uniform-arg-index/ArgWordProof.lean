import ArgWordSpec
set_option autoImplicit false
namespace RevisedBenchmark.ArgWord
open RevisedBenchmark.ArgReuse
def finiteOne : Value 1 := some 1
set_option maxRecDepth 8192 in
theorem witness (d : Direction) : reduce 8 129 d finiteOne = (finiteOne, 128) := by
  cases d <;> decide

theorem refuted (d : Direction) : ¬ Case d := by
  intro h
  have eq := h 1 8 129 (by decide) (by decide) finiteOne
  rw [witness] at eq
  exact (by decide : (128 : BitVec 8) ≠ 0) (congrArg Prod.snd eq)
example : ¬ Case .minimum := refuted _
example : ¬ Case .maximum := refuted _
#print axioms refuted
end RevisedBenchmark.ArgWord
