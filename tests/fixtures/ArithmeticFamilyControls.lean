import TensorRewrite.Theory.ArithmeticBroadcast
import TensorRewrite.Theory.ArithmeticFloatCounterexamples
import Mathlib.Tactic.FinCases
import TensorRewrite.Pilot.LinearIndexLemmas

open TensorRewrite TensorRewrite.Pilot TensorRewrite.Theory ArithmeticFamily

/-- Render actual arithmetic expression structure independently of its evaluator. -/
def treeTokens : Expr → List String
  | .input n => ["x" ++ toString n]
  | .zero => ["zero"] | .one => ["one"] | .ofPredicate n => ["p" ++ toString n]
  | .neg x => treeTokens x ++ ["neg"]
  | .add x y => treeTokens x ++ treeTokens y ++ ["add"]
  | .sub x y => treeTokens x ++ treeTokens y ++ ["sub"]
  | .mul x y => treeTokens x ++ treeTokens y ++ ["mul"]
  | .select n x y => treeTokens x ++ treeTokens y ++ ["sel" ++ toString n]

/-- Boundary and signed integer tuples supplement exhaustive small modular-word inputs. -/
def arithmeticSamples : List (List Int) :=
  [[0,0,0,0],[1,1,1,1],[-1,-1,-1,-1],[1,2,3,4],[-1,2,-3,4],
   [0,1,-1,2],[7,1,3,5],[15,1,7,9],[255,1,-1,2],[-256,257,3,-5],
   [16777216,1,-16777216,3],[3,5,7,11],[-2,-1,0,1],[1,0,0,0],
   [0,1,0,0],[0,0,1,0],[0,0,0,1],[2,3,5,7],[8,8,8,8],[127,128,255,-128]]

/-- Evaluate every actual rule at one scalar tensor coordinate with the selected exact ring. -/
def arithmeticValues {α : Type} [CommRing α] (domain : String) (width number : Nat)
    (encode : α → Int) (values : List Int) : IO Unit := do
  let shape : Shape 0 := Fin.elim0
  let inputs : Nat → Tensor shape α := fun n => Tensor.constant ((values[n]?.getD 0 : Int) : α)
  for predicate in [false,true] do
    let predicates : Nat → Tensor shape Bool := fun _ => Tensor.constant predicate
    for rule in allRules do
      let left := rule.lhs.eval (Operations.exact α) inputs predicates (fun a => Fin.elim0 a)
      let right := rule.rhs.eval (Operations.exact α) inputs predicates (fun a => Fin.elim0 a)
      IO.println s!"ARITH_VALUE domain={domain} width={width} sample={number} values={values} predicate={predicate} key={rule.key} lhs={encode left} rhs={encode right}"

/-- Exhaustive controls for all input quadruples at word widths zero through two. -/
def wordArithmeticControls (width : Nat) : IO Unit := do
  let mut number := 0
  for a in List.range (2 ^ width) do
    for b in List.range (2 ^ width) do
      for c in List.range (2 ^ width) do
        for d in List.range (2 ^ width) do
          arithmeticValues "word" width number (fun x : BitVec width => Int.ofNat x.toNat)
            [a,b,c,d]
          number := number + 1

/-- Compare actual signed-axis Broadcast graph evaluations, including all product orders. -/
def arithmeticGraph {α : Type} [CommRing α] {smallRank rank : Nat}
    {smallShape : Shape smallRank} {shape : Shape rank} (scenario : Nat)
    (domain : String) (width : Nat) (encode : α → Int)
    (axes : IndexMaps.BroadcastAxes smallRank rank)
    (extents : ∀ axis, smallShape axis = shape (axes.decode axis)) : IO Unit := do
  let input : Tensor shape α := fun index =>
    ((5 * Int.ofNat (LinearIndex.linearize shape index).val - 3 : Int) : α)
  let first : Tensor smallShape α := fun index =>
    ((2 * Int.ofNat (LinearIndex.linearize smallShape index).val - 2 : Int) : α)
  let second : Tensor smallShape α := fun index =>
    ((3 - Int.ofNat (LinearIndex.linearize smallShape index).val : Int) : α)
  let broadcast := Tensor.reindex (IndexMaps.broadcastIndex axes extents)
  IO.println s!"ARITH_GRAPH_COUNT domain={domain} width={width} scenario={scenario} small={(Vector.ofFn smallShape).toList} output={(Vector.ofFn shape).toList} axes={axes.values.toList}"
  for position in List.finRange (LinearIndex.elementCount shape) do
    let index := LinearIndex.delinearize shape position
    let left := Tensor.map₂ (· - ·) input (broadcast first)
    let right := Tensor.map₂ (· + ·) input (broadcast (Tensor.map (- ·) first))
    IO.println s!"ARITH_GRAPH domain={domain} width={width} scenario={scenario} output={position.val} rule=0 inner=false outer=false lhs={encode (left index)} rhs={encode (right index)}"
    for inner in [false,true] do
      for outer in [false,true] do
        let left := OperandOrder.map₂ (· + ·) outer
          (OperandOrder.map₂ (· + ·) inner input (broadcast first)) (broadcast second)
        let right := Tensor.map₂ (· + ·) input (broadcast (Tensor.map₂ (· + ·) first second))
        IO.println s!"ARITH_GRAPH domain={domain} width={width} scenario={scenario} output={position.val} rule=1 inner={inner} outer={outer} lhs={encode (left index)} rhs={encode (right index)}"
        if !inner then
          let left := OperandOrder.map₂ (· + ·) outer
            (Tensor.map₂ (· - ·) (broadcast first) input) (broadcast second)
          let right := Tensor.map₂ (· - ·) (broadcast (Tensor.map₂ (· + ·) first second)) input
          IO.println s!"ARITH_GRAPH domain={domain} width={width} scenario={scenario} output={position.val} rule=2 inner=false outer={outer} lhs={encode (left index)} rhs={encode (right index)}"
        let left := OperandOrder.map₂ (· * ·) outer
          (OperandOrder.map₂ (· * ·) inner input (broadcast first)) (broadcast second)
        let right := Tensor.map₂ (· * ·) input (broadcast (Tensor.map₂ (· * ·) first second))
        IO.println s!"ARITH_GRAPH domain={domain} width={width} scenario={scenario} output={position.val} rule=3 inner={inner} outer={outer} lhs={encode (left index)} rhs={encode (right index)}"
        let factor : α := -3
        let left := OperandOrder.map₂ (· * ·) outer
          (OperandOrder.map₂ (· * ·) inner input (Tensor.constant factor)) (broadcast first)
        let right := Tensor.map₂ (· * ·) input
          (broadcast (Tensor.map₂ (· * ·) first (Tensor.constant factor)))
        IO.println s!"ARITH_GRAPH domain={domain} width={width} scenario={scenario} output={position.val} rule=4 inner={inner} outer={outer} lhs={encode (left index)} rhs={encode (right index)}"

/-- Empty, scalar, retained-axis and permuted-axis Broadcast profiles. -/
def arithmeticGraphControls {α : Type} [CommRing α] (domain : String) (width : Nat)
    (encode : α → Int) : IO Unit := do
  arithmeticGraph (α := α) (smallShape := fun _ : Fin 1 => 2)
    (shape := Fin.cases 3 (fun _ : Fin 1 => 2)) 0 domain width encode ⟨#v[1], by decide⟩ (by decide)
  arithmeticGraph (α := α) (smallShape := fun _ : Fin 1 => 2)
    (shape := Fin.cases 0 (fun _ : Fin 1 => 2)) 1 domain width encode ⟨#v[1], by decide⟩ (by decide)
  arithmeticGraph (α := α) (smallShape := (Fin.elim0 : Shape 0))
    (shape := fun _ : Fin 2 => 2) 2 domain width encode ⟨#v[], fun a => Fin.elim0 a⟩
    (fun a => Fin.elim0 a)
  arithmeticGraph (α := α) (smallShape := Fin.cases 2 (fun _ : Fin 1 => 3))
    (shape := Fin.cases 3 (fun _ : Fin 1 => 2)) 3 domain width encode ⟨#v[1,0], by decide⟩ (by decide)
  arithmeticGraph (α := α) (smallShape := fun _ : Fin 1 => 0)
    (shape := Fin.cases 0 (fun _ : Fin 1 => 3)) 4 domain width encode ⟨#v[0], by decide⟩ (by decide)

#eval show IO Unit from do
  for rule in allRules do
    IO.println s!"ARITH_TREE key={rule.key} lhs={String.intercalate " " (treeTokens rule.lhs)} | rhs={String.intercalate " " (treeTokens rule.rhs)}"
    for domain in ["integer","real","complex","word_all_widths"] do
      IO.println s!"ARITH_PROFILE domain={domain} key={rule.key}"
  for (values,number) in arithmeticSamples.zipIdx do
    arithmeticValues "integer" 0 number (fun x : Int => x) values
  for width in [0,1,2] do wordArithmeticControls width
  for width in [4,8] do
    for (values,number) in arithmeticSamples.zipIdx do
      arithmeticValues "word" width number (fun x : BitVec width => Int.ofNat x.toNat) values
  arithmeticGraphControls "integer" 0 (fun x : Int => x)
  arithmeticGraphControls "word" 3 (fun x : BitVec 3 => Int.ofNat x.toNat)
  let addValues := fun n => if n = 0 then 0x4b800000 else if n = 1 then 0x3f800000 else 0xcb800000
  IO.println s!"ARITH_FLOAT key=add_assoc_00 lhs={binary32Bits (Rule.addAssoc false false).lhs addValues} rhs={binary32Bits (Rule.addAssoc false false).rhs addValues}"
  let mulValues := fun n => if n = 0 then 1 else if n = 1 then 0x3f000000 else 0x40000000
  IO.println s!"ARITH_FLOAT key=mul_assoc_00 lhs={binary32Bits (Rule.mulAssoc false false).lhs mulValues} rhs={binary32Bits (Rule.mulAssoc false false).rhs mulValues}"
  IO.println s!"ARITH_FLOAT key=mul_zero_right lhs={binary32Bits Rule.mulZeroRight.lhs (fun _ => 0x7f800000)} rhs={binary32Bits Rule.mulZeroRight.rhs (fun _ => 0x7f800000)}"
