import TensorRewrite

open TensorRewrite.Pilot.ReducerIndex.GatherLiterals

example : originalIndex 129 0#8 = selectedIndex 129 0#8 := by
  rfl
