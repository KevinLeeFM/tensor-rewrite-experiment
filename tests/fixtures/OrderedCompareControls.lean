import TensorRewrite

open TensorRewrite.Pilot.OrderedCompareProfile

#eval IO.println ("ORDERED_COMPARE_MODEL left_nan_true_allowed=" ++
  toString (decide (IsOrderedCompatible quietNaN zero true)) ++
  " right_nan_true_allowed=" ++ toString (decide (IsOrderedCompatible zero quietNaN true)) ++
  " false_allowed=" ++ toString (decide (IsOrderedCompatible quietNaN zero false)))
