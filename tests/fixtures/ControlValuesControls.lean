import TensorRewrite.Theory.ControlValuesCounterexamples
import TensorRewrite.Libraries.FloatingPoint
import FloatLib.Floats.Formats.BinaryInterchange.Configured.Value.Core

open TensorRewrite.Pilot TensorRewrite.Theory.ControlValues FloatLib.Floats

private def scalarIndex : Index (Fin.elim0 : Shape 0) := fun axis => Fin.elim0 axis

private def rectangle : Shape 2 := fun axis => if axis.val = 0 then 2 else 3

private def coordinate (row : Fin 2) (column : Fin 3) : Index rectangle :=
  fun axis => if isFirst : axis.val = 0 then by
    simpa [rectangle, isFirst] using row
  else by
    simpa [rectangle, isFirst] using column

private def axisName : Direction → String
  | .lt => "lt" | .le => "le" | .gt => "gt" | .ge => "ge" | .eq => "eq" | .ne => "ne"

private def selectedComparison (direction : Direction) (left right : Bool) : Bool :=
  match direction with
  | .lt | .le => left && right
  | .gt | .ge => left || right
  | .eq => right
  | .ne => left

private def broadcastRows (axis : Fin 2) : IO Unit := do
  let shape : Shape 1 := fun _ => rectangle axis
  let axes : IndexMaps.BroadcastAxes 1 2 := {
    values := ⟨#[Int.ofNat axis.val], rfl⟩
    valid := fun component => by
      have zero : component = 0 := Fin.eq_zero component
      subst component
      simp
      omega
  }
  let extents : ∀ component, shape component = rectangle (axes.decode component) := by
    intro component
    have zero : component = 0 := Fin.eq_zero component
    subst component
    rfl
  let predicate : Tensor shape Bool := fun index => (index 0).val % 2 == 0
  for row in List.finRange 2 do
    for column in List.finRange 3 do
      let index := coordinate row column
      let expanded := broadcast axes extents predicate
      let original := select expanded (Tensor.constant false) (Tensor.constant true)
      let replacement := broadcast axes extents (Tensor.map Bool.not predicate)
      IO.println s!"CV_BROADCAST axis={axis.val} row={row.val} column={column.val} predicate={(expanded index).toNat} source={(original index).toNat} target={(replacement index).toNat}"

#eval show IO Unit from do
  for predicate in [false, true] do
    for left in [(-17 : Int), 0, 91] do
      for right in [(-17 : Int), 0, 91] do
        let result := select (Tensor.constant predicate) (Tensor.constant left)
          (Tensor.constant right) scalarIndex
        IO.println s!"CV_SELECT predicate={predicate.toNat} left={left} right={right} value={result}"
  for direction in [Direction.lt, .le, .gt, .ge, .eq, .ne] do
    for left in [false, true] do
      for right in [false, true] do
        let predicate := compare direction left right
        let result := select (Tensor.constant predicate) (Tensor.constant left)
          (Tensor.constant right) scalarIndex
        IO.println s!"CV_COMPARE direction={axisName direction} left={left.toNat} right={right.toNat} predicate={predicate.toNat} source={result.toNat} target={(selectedComparison direction left right).toNat}"
  broadcastRows 0
  broadcastRows 1
  for predicate in [false, true] do
    for row in List.finRange 2 do
      for column in List.finRange 3 do
        let expanded : Tensor rectangle Bool := broadcast (scalarAxes 2)
          (fun axis => Fin.elim0 axis) (Tensor.constant (shape := (Fin.elim0 : Shape 0)) predicate)
        let result := select expanded (Tensor.constant true) (Tensor.constant false)
        IO.println s!"CV_SCALAR row={row.val} column={column.val} predicate={predicate.toNat} value={(result (coordinate row column)).toNat}"
  for first in List.finRange 3 do
    for second in List.finRange 3 do
      for row in List.finRange 2 do
        for column in List.finRange 3 do
          let index := coordinate row column
          let inputs : Fin 3 → Tensor rectangle Int := fun argument point =>
            Int.ofNat ((argument.val + 1) * (3 * (point 0).val + (point 1).val)) - 3
          let parameters : Fin 2 → Fin 3 := fun argument =>
            if argument.val = 0 then first else second
          let operation : (Fin 2 → Int) → Int := fun values => values 0 - 2 * values 1
          let original := mapTensor (fun values => operation (fun arg => values (parameters arg))) inputs
          let replacement := elementwise operation (fun arg => inputs (parameters arg))
          IO.println s!"CV_MAP first={first.val} second={second.val} row={row.val} column={column.val} source={original index} target={replacement index}"
  for flag in [false, true] do
    for value in [(-17 : Int), 0, 91] do
      let types : Fin 2 → Type := fun argument => if argument = 0 then Int else Bool
      let inputs : (argument : Fin 2) → Tensor (Fin.elim0 : Shape 0) (types argument) :=
        fun argument => by
          by_cases first : argument = 0
          · simpa [types, first] using
              (Tensor.constant (shape := (Fin.elim0 : Shape 0)) value)
          · simpa [types, first] using
              (Tensor.constant (shape := (Fin.elim0 : Shape 0)) flag)
      let body : ((argument : Fin 2) → types argument) → Int := fun values =>
        let flagValue : Bool := by simpa [types] using values 1
        let intValue : Int := by simpa [types] using values 0
        match flagValue with
        | true => intValue + 1
        | false => intValue - 1
      IO.println s!"CV_HETERO flag={flag.toNat} input={value} value={mapTensor body inputs scalarIndex}"
  for predicate in [false, true] do
    for state in [0, 5] do
      let arguments : Fin 2 → Nat := fun branch => if branch.val = 0 then 11 else 13
      let branches : Fin 2 → Nat → Nat → Observed Nat := fun branch argument current =>
        ⟨argument + current, [branch.val]⟩
      let original := indexedConditional (booleanIndex predicate) arguments branches state
      let replacement := predicateConditional predicate (arguments 1) (branches 1)
        (arguments 0) (branches 0) state
      IO.println s!"CV_CONDITIONAL predicate={predicate.toNat} state={state} source={original.value} target={replacement.value} source_event={original.events.headD 99} target_event={replacement.events.headD 99}"
  for predicate in [false, true] do
    for pair in [(0, 0x80000000), (0x7fc01234, 0x7f801234), (0x7f800000, 0xff800000)] do
      let left : Binary32 := ExecFloat.Binary.ofNatBits pair.1
      let right : Binary32 := ExecFloat.Binary.ofNatBits pair.2
      let result := select (Tensor.constant predicate) (Tensor.constant left)
        (Tensor.constant right) scalarIndex
      IO.println s!"CV_FLOAT predicate={predicate.toNat} left={pair.1} right={pair.2} bits={ExecFloat.Binary.toNatBits result}"
  IO.println s!"CV_EMPTY coordinates={(List.finRange 0).length}"
