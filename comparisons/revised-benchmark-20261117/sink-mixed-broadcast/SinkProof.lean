import SinkSpec
namespace RevisedBenchmark.SinkMixed
theorem verified : Goal := by
  intro r q n s t axis ordered fit types β args user
  funext o
  apply congrArg user
  funext k
  cases args k <;> rfl
#print axioms verified
end RevisedBenchmark.SinkMixed
