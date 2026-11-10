import TensorRewrite

open TensorRewrite.Pilot
open TensorRewrite.Pilot.DenseLayout

example (permutation : AxisPermutation 2) (inputLayout outputLayout : DenseLayout 2) :
    MinorOrderMatches permutation inputLayout outputLayout := by rfl
