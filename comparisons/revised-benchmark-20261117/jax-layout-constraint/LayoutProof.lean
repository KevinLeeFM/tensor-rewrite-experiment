import LayoutSpec
namespace RevisedBenchmark.LayoutConstraint
open CopyChain
theorem verified : Goal := by
  intro I α n same src dst h data i
  cases same with
  | true => exact congrArg data (h rfl i)
  | false => simp [replacement, original, copy, dst.decode_encode]
#print axioms verified
end RevisedBenchmark.LayoutConstraint
