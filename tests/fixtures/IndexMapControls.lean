import TensorRewrite

open TensorRewrite.Pilot
open TensorRewrite.Pilot.IndexMaps

def inputShape : Shape 2 := fun axis => if axis == 0 then 2 else 3
def outputShape : Shape 3 := fun axis => if axis == 0 then 2 else if axis == 1 then 4 else 3
def broadcastAxes : BroadcastAxes 2 3 :=
  { values := #v[0, 2], valid := by decide }

theorem broadcastExtents : ∀ axis, inputShape axis = outputShape (broadcastAxes.decode axis) := by
  decide

def broadcastOutput : Index outputShape :=
  fun axis => if h : axis = 0 then ⟨1, by subst axis; decide⟩
    else if h1 : axis = 1 then ⟨3, by subst axis; decide⟩
    else ⟨2, by simp [outputShape, h, h1]⟩

-- Nonuniform coordinate labels distinguish projection from an arbitrary map.
example : (broadcastIndex broadcastAxes broadcastExtents broadcastOutput 0).val = 1 := by rfl
example : (broadcastIndex broadcastAxes broadcastExtents broadcastOutput 1).val = 2 := by rfl

def sliceInputShape : Shape 2 := fun axis => if axis == 0 then 6 else 7
def sliceOutputShape : Shape 2 := fun axis => if axis == 0 then 3 else 2
def sliceAxes : Fin 2 → SliceShape.Axis := fun axis =>
  if axis == 0 then { start := 1, limit := 6, stride := 2 }
  else { start := 2, limit := 7, stride := 3 }

theorem sliceValid : ∀ axis, SliceShape.IsWellFormed
    (sliceInputShape axis) (sliceOutputShape axis) (sliceAxes axis) := by
  decide

def sliceCoordinate (row : Fin 3) (col : Fin 2) : Index sliceOutputShape :=
  fun axis => if h : axis = 0 then Fin.cast (by subst axis; rfl) row
    else Fin.cast (by
      have haxis : axis = 1 := by omega
      subst axis
      rfl) col

def sliceLabel (row : Fin 3) (col : Fin 2) : Nat :=
  let coordinate := sliceIndex sliceAxes sliceValid (sliceCoordinate row col)
  (coordinate 0).val * 7 + (coordinate 1).val

example : [sliceLabel 0 0, sliceLabel 0 1, sliceLabel 1 0,
    sliceLabel 1 1, sliceLabel 2 0, sliceLabel 2 1] = [9, 12, 23, 26, 37, 40] := by rfl

-- The legal empty case has no output coordinate requiring an input address.
example : SliceShape.IsWellFormed 4 0 { start := 1, limit := 1, stride := 2 } := by decide
example : ¬ SliceShape.IsWellFormed 4 1 { start := 1, limit := 1, stride := 2 } := by decide
example : ¬ SliceShape.IsWellFormed 4 1 { start := 1, limit := 3, stride := 0 } := by decide
example : SliceShape.IsWellFormed 4 1 { start := 1, limit := 3, stride := 5 } := by decide

example : ¬ (∀ axis : Fin 1, 0 ≤ (#v[-1] : Vector Int 1)[axis] ∧
    (#v[-1] : Vector Int 1)[axis] < (2 : Int)) := by decide

-- These evaluated diagnostics are compared with independently run native HLO;
-- the general bounds and the coordinate examples above remain kernel proofs.
#eval IO.println ("INDEX_MAP_MODEL_BROADCAST selected=" ++ toString
  ((broadcastIndex broadcastAxes broadcastExtents broadcastOutput 0).val * 3 +
    (broadcastIndex broadcastAxes broadcastExtents broadcastOutput 1).val))
#eval IO.println ("INDEX_MAP_MODEL_SLICE values=" ++ String.intercalate ","
  ([sliceLabel 0 0, sliceLabel 0 1, sliceLabel 1 0,
    sliceLabel 1 1, sliceLabel 2 0, sliceLabel 2 1].map toString))
#eval IO.println ("INDEX_MAP_MODEL_EMPTY elements=" ++ toString
  (({ start := 1, limit := 1, stride := 2 } : SliceShape.Axis).elementCount))
#eval IO.println ("INDEX_MAP_MODEL_LARGE_STRIDE value=" ++ toString
  ((sliceIndex (inputShape := fun _ : Fin 1 => 4) (outputShape := fun _ => 1)
    (fun _ => { start := 1, limit := 3, stride := 5 }) (by decide)
    (fun _ => 0) 0).val))
