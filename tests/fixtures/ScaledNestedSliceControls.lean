import TensorRewrite

open TensorRewrite.Pilot.ScaledNestedSlice

#eval do
  for (name, multiplier) in [("scaled", (7 : BitVec 32)), ("negative_multiplier", -3),
      ("one_multiplier", 1), ("zero_multiplier", 0)] do
    let before := (original 1 (by decide) multiplier 1 2 witnessIndex).toInt
    let after := (rewritten 1 (by decide) 1 2 witnessIndex).toInt
    IO.println ("SCALED_NESTED_MODEL case=" ++ name ++ " before=" ++ toString before ++
      " after=" ++ toString after)
