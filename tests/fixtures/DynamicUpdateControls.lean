import TensorRewrite.Theory.DynamicUpdateCounterexamples
import TensorRewrite.Pilot.LinearIndexLemmas
import Mathlib.Data.BitVec

open TensorRewrite.Pilot TensorRewrite.Theory.DynamicUpdate FloatLib.Floats

/-- Actual tensor graph pairs with independent shape, membership and clamping observations. -/
def dynamicUpdateProfile {α : Type} [CommRing α] {rank : Nat} {outer inner : Shape rank}
    (domain : String) (number : Nat) (encode : α → Int) (window : Window outer inner) : IO Unit := do
  let base : Tensor outer α := fun i => ((13 * (LinearIndex.linearize outer i).val - 7 : Int) : α)
  let update : Tensor inner α := fun i => ((100 + 3 * (LinearIndex.linearize inner i).val : Int) : α)
  let predicate : Tensor outer Bool := fun i => (LinearIndex.linearize outer i).val % 2 == 0
  let smallShape : Shape rank := fun a => min (inner a) 1
  let second : Window inner smallShape :=
    ⟨(fun a => if a.val % 2 == 0 then 5 else -1), fun _ => Nat.min_le_left _ _⟩
  let final : Tensor smallShape α := fun i =>
    ((900 + 5 * (LinearIndex.linearize smallShape i).val : Int) : α)
  let combined := window.compose second
  let starts := (Vector.ofFn window.start).toList
  let limits := (Vector.ofFn fun a => (window.staticAxes a).limit).toList
  IO.println s!"DU_PROFILE domain={domain} profile={number} outer={(Vector.ofFn outer).toList} inner={(Vector.ofFn inner).toList} raw={(Vector.ofFn window.starts).toList} start={starts} limits={limits} combined={(Vector.ofFn combined.start).toList}"
  let emit := fun (kind : String) (position : Nat) (left right : α) =>
    IO.println s!"DU_VALUE domain={domain} profile={number} kind={kind} output={position} lhs={encode left} rhs={encode right}"
  for position in List.finRange (LinearIndex.elementCount outer) do
    let i := LinearIndex.delinearize outer position
    let decoded := match window.locate i with
      | none => "none"
      | some j => toString ((Vector.ofFn fun a => (j a).val).toList)
    IO.println s!"DU_LOCATE domain={domain} profile={number} output={position.val} decoded={decoded}"
    let written := window.update base update
    emit "write" position.val (written i) (written i)
    emit "zero_axes" position.val (window.zeroFullAxes.update base update i) (written i)
    emit "map" position.val (-written i) (window.update (Tensor.map (- ·) base)
      (Tensor.map (- ·) update) i)
    emit "self" position.val (window.update base (window.slice base) i) (base i)
    emit "select_false" position.val (if predicate i then base i else written i)
      (window.update base (fun j => if window.slice predicate j then window.slice base j
        else update j) i)
    emit "select_true" position.val (if predicate i then written i else base i)
      (window.update base (fun j => if window.slice predicate j then update j
        else window.slice base j) i)
    for p in [false,true] do
      emit ("scalar_false_" ++ toString p) position.val (if p then base i else written i)
        (window.update base (fun j => if p then window.slice base j else update j) i)
      emit ("scalar_true_" ++ toString p) position.val (if p then written i else base i)
        (window.update base (fun j => if p then update j else window.slice base j) i)
    let sparse := window.update (Tensor.constant 0) update
    emit "add_right" position.val (base i + sparse i)
      (window.update base (fun j => window.slice base j + update j) i)
    emit "add_left" position.val (sparse i + base i)
      (window.update base (fun j => update j + window.slice base j) i)
    emit "nested" position.val (window.update base
      (second.update (window.slice base) final) i) (combined.update base final i)
  for position in List.finRange (LinearIndex.elementCount inner) do
    let i := LinearIndex.delinearize inner position
    emit "slice_update" position.val (window.slice (window.update base update) i) (update i)
    emit "static" position.val (window.slice base i)
      (base (IndexMaps.sliceIndex window.staticAxes (static_axes_valid window) i))
    emit "static_slice_update" position.val
      (window.update base update
        (IndexMaps.sliceIndex window.staticAxes (static_axes_valid window) i)) (update i)
    emit "slice_zero_axes" position.val (window.zeroFullAxes.slice base i) (window.slice base i)
  for position in List.finRange (LinearIndex.elementCount smallShape) do
    let i := LinearIndex.delinearize smallShape position
    emit "compose" position.val (second.slice (window.slice base) i) (combined.slice base i)
    emit "static_inside" position.val
      (window.update base update (IndexMaps.sliceIndex combined.staticAxes
        (static_axes_valid combined) i)) (second.slice update i)
    emit "inside" position.val (combined.slice (window.update base update) i) (second.slice update i)

/-- Exhaust all small valid extents and mixed signed raw starts; retain empty and scalar windows. -/
def dynamicUpdateControls {α : Type} [CommRing α] (domain : String)
    (encode : α → Int) : IO Unit := do
  let mut number := 0
  dynamicUpdateProfile (α := α) domain number encode
    (⟨Fin.elim0, fun a => Fin.elim0 a⟩ : Window (Fin.elim0 : Shape 0) Fin.elim0)
  number := number + 1
  for extent in [0,1,2,3] do
    for width in List.finRange (extent + 1) do
      for start in [-2,0,1,5] do
        let window : Window (fun _ : Fin 1 => extent) (fun _ => width.val) :=
          ⟨fun _ => start, fun _ => by have bound := width.isLt; omega⟩
        dynamicUpdateProfile (α := α) domain number encode window
        number := number + 1
  for (a,b) in [(2,2),(0,2),(2,0)] do
    for x in List.finRange (a + 1) do
      for y in List.finRange (b + 1) do
        for first in [-2,0,1,5] do
          for second in [-2,0,1,5] do
            let window : Window (Fin.cases a (fun _ : Fin 1 => b))
                (Fin.cases x.val (fun _ : Fin 1 => y.val)) :=
              ⟨Fin.cases first (fun _ => second), fun axis => by
                refine Fin.cases ?_ (fun tail => ?_) axis
                · change x.val ≤ a
                  have bound := x.isLt; omega
                · change y.val ≤ b
                  have bound := y.isLt; omega⟩
            dynamicUpdateProfile (α := α) domain number encode window
            number := number + 1

#eval show IO Unit from do
  dynamicUpdateControls (α := Int) "integer" id
  dynamicUpdateControls (α := BitVec 8) "word8" (fun x => Int.ofNat x.toNat)
  let window := diagnosticLineWindow 2 1 (by decide) 1
  let zero : Binary32 := ExecFloat.Binary.ofNatBits 0
  let negative : Binary32 := ExecFloat.Binary.ofNatBits 0x80000000
  let base := Tensor.constant (shape := fun _ : Fin 1 => 2) negative
  let update := Tensor.constant (shape := fun _ : Fin 1 => 1) zero
  let index : Index (fun _ : Fin 1 => 2) := fun _ => 0
  let left := base index |> fun x => ExecFloat.add x (window.update (Tensor.constant zero) update index)
  let right := window.update base (Tensor.map₂ ExecFloat.add (window.slice base) update) index
  IO.println s!"DU_IEEE lhs={ExecFloat.Binary.toNatBits left} rhs={ExecFloat.Binary.toNatBits right}"
