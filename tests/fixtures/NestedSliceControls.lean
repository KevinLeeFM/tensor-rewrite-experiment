import TensorRewrite

open TensorRewrite.Pilot
open TensorRewrite.Pilot.DynamicIndex
open TensorRewrite.Pilot.NestedUnsigned64

example : combinedStart 10 6 2 (-99) 99 = 4 := by decide
example : combinedStart 10 6 2 99 99 = 8 := by decide
example : combinedStart 0 0 0 99 (-99) = 0 := by decide
example : combinedStart 10 10 2 99 1 = 1 := by decide
example : combinedStart 10 6 6 1 99 = 1 := by decide

def innerStarts : List (BitVec 64 × BitVec 64) :=
  [(BitVec.ofNat 64 (2 ^ 63), 1), (1, BitVec.ofNat 64 (2 ^ 63)),
    (BitVec.ofNat 64 (2 ^ 63), BitVec.ofNat 64 (2 ^ 63))]

#eval IO.println ("NESTED_SLICE_MODEL before=" ++ String.intercalate ","
  ((innerStarts.map fun (inner, outer) => originalStart inner outer).map toString))
#eval IO.println ("NESTED_SLICE_MODEL after=" ++ String.intercalate ","
  ((innerStarts.map fun (inner, outer) => rewrittenStart inner outer).map toString))
