import TensorRewrite

open TensorRewrite.Pilot
open TensorRewrite.Pilot.DynamicIndex

example : clampStart 5 2 (-99) = 0 := by rfl
example : clampStart 5 2 99 = 3 := by rfl
example : clampStart 5 5 (-99) = 0 := by rfl
example : clampStart 0 0 99 = 0 := by rfl
example : clampStart 5 0 99 = 5 := by rfl

def shape5 : Shape 1 := fun _ => 5
def shape2 : Shape 1 := fun _ => 2
example : (dynamicSliceIndex (inputShape := shape5) (outputShape := shape2)
    (fun _ => -99) (by decide) (fun _ => ⟨1, by change 1 < 2; decide⟩) 0).val = 1 := by rfl
example : (dynamicSliceIndex (inputShape := shape5) (outputShape := shape2)
    (fun _ => 99) (by decide) (fun _ => ⟨1, by change 1 < 2; decide⟩) 0).val = 4 := by rfl

def signed32Cases : List Int := [-99, -1, 0, 1, 3, 4, 99]
def signed64Cases : List Int := [-(2 ^ 63), -1, 0, 1, 2 ^ 63 - 1]
def unsigned32Cases : List Nat := [0, 1, 2 ^ 32 - 1]
def unsigned64Cases : List Nat := [0, 1, 2 ^ 63 - 1, 2 ^ 63, 2 ^ 64 - 1]

example : signed32Cases.map (fun value => clampStart 5 2
    (signedValue (BitVec.ofInt 32 value))) = [0, 0, 0, 1, 3, 3, 3] := by decide
example : unsigned64Cases.map (fun value => clampStart 5 2
    (unsignedValue (BitVec.ofNat 64 value))) = [0, 1, 3, 3, 3] := by decide
example : unsigned64Cases.map (fun value => clampStart 5 2
    (evaluatorUnsigned64 (BitVec.ofNat 64 value))) = [0, 1, 3, 0, 0] := by decide

#eval IO.println ("DYNAMIC_INDEX_MODEL s32=" ++ String.intercalate ","
  ((signed32Cases.map fun value => clampStart 5 2
    (signedValue (BitVec.ofInt 32 value))).map toString))
#eval IO.println ("DYNAMIC_INDEX_MODEL s64=" ++ String.intercalate ","
  ((signed64Cases.map fun value => clampStart 5 2
    (signedValue (BitVec.ofInt 64 value))).map toString))
#eval IO.println ("DYNAMIC_INDEX_MODEL u32=" ++ String.intercalate ","
  ((unsigned32Cases.map fun value => clampStart 5 2
    (unsignedValue (BitVec.ofNat 32 value))).map toString))
#eval IO.println ("DYNAMIC_INDEX_MODEL u64_logical=" ++ String.intercalate ","
  ((unsigned64Cases.map fun value => clampStart 5 2
    (unsignedValue (BitVec.ofNat 64 value))).map toString))
#eval IO.println ("DYNAMIC_INDEX_MODEL u64_evaluator=" ++ String.intercalate ","
  ((unsigned64Cases.map fun value => clampStart 5 2
    (evaluatorUnsigned64 (BitVec.ofNat 64 value))).map toString))
