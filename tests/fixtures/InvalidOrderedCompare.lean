import TensorRewrite

open TensorRewrite.Pilot.OrderedCompareProfile

example : IsOrderedCompatible quietNaN zero true := by
  intro nan
  rfl
