import ExpandSpec
namespace RevisedBenchmark.SinkMixed
theorem expanded : ExpandedGoal := by
  intro r q n s t axis ordered fit types β args user
  funext o
  apply congrArg user
  funext k
  cases args k <;> rfl
#print axioms expanded
end RevisedBenchmark.SinkMixed
