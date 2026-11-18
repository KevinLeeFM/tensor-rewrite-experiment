import NibbleProof
namespace RevisedBenchmark.BitcastPacked
example : hloBytes scalarShape = 1 ∧ hloBytes packedShape = 1 ∧
    literalBytes scalarShape = 1 ∧ literalBytes packedShape = 2 := by decide
example : oldJoin true 1 1 = some [17] ∧ oldJoin false 1 1 = some [17] ∧
    newJoin 1 1 = some [1] := by decide
example : oldSplit true 17 = some [1,1] ∧ oldSplit false 17 = some [1,1] ∧
    newSplit 17 = none := by decide
example : oldJoin true 3 0 = newJoin 3 0 := by decide
example : oldJoin false 0 0 = newJoin 0 0 := by decide
example : ¬ contiguous {packedShape with explicitBits := 0} := by unfold contiguous; decide
#check (verified : Goal)
end RevisedBenchmark.BitcastPacked
