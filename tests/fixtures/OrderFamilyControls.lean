import TensorRewrite.Theory.OrderCounterexamples

open TensorRewrite.Pilot TensorRewrite.Theory.OrderFamily FloatLib.Floats

/-- Print the actual value-expression tree without consulting its evaluator. -/
def orderTree : Expr → String
  | .input n => "x" ++ toString n
  | .zero => "zero"
  | .minimum x y => orderTree x ++ " " ++ orderTree y ++ " min"
  | .maximum x y => orderTree x ++ " " ++ orderTree y ++ " max"
  | .clamp lo x hi => orderTree lo ++ " " ++ orderTree x ++ " " ++ orderTree hi ++ " clamp"

/-- Print actual predicate expressions and comparison direction. -/
def orderPredicateTree : Predicate → String
  | .constant b => if b then "true" else "false"
  | .compare d x y => orderTree x ++ " " ++ orderTree y ++ " " ++ (match d with
      | .lt => "lt" | .le => "le" | .gt => "gt" | .ge => "ge" | .eq => "eq" | .ne => "ne")
  | .and x y => orderPredicateTree x ++ " " ++ orderPredicateTree y ++ " and"

/-- Print the actual root tag and tree. -/
def orderGraphTree : Graph → String
  | .value x => orderTree x
  | .predicate p => orderPredicateTree p

/-- Render a whole scalar tensor result with its value/predicate tag. -/
def orderResult {α : Type} (encode : α → Int) :
    Tensor (Fin.elim0 : Shape 0) α ⊕ Tensor (Fin.elim0 : Shape 0) Bool → String
  | .inl value => "v:" ++ toString (encode (value (fun axis => Fin.elim0 axis)))
  | .inr value => "p:" ++ if value (fun axis => Fin.elim0 axis) then "1" else "0"

/-- Run every actual rule and the admitted-domain check at one scalar coordinate. -/
def orderRows {α : Type} [LinearOrder α] [Zero α] (domain : String) (width sample : Nat)
    (decode : α → Int) (values : List Int) (convert : Int → α) : IO Unit := do
  let shape : Shape 0 := Fin.elim0
  let scalar : Nat → α := fun n => convert (values[n]?.getD 0)
  let inputs : Nat → Tensor shape α := fun n => Tensor.constant (scalar n)
  let raw := String.intercalate "," (values.map toString)
  let decoded := String.intercalate "," ((values.map convert).map (fun x => toString (decode x)))
  for rule in allRules do
    let left := orderResult decode (rule.lhs.eval (Operations.exact α) inputs)
    let right := orderResult decode (rule.rhs.eval (Operations.exact α) inputs)
    let admitted := rule.admittedAt scalar
    IO.println s!"ORDER_ROW domain={domain} width={width} sample={sample} raw={raw} decoded={decoded} key={rule.key} admitted={admitted} lhs={left} rhs={right}"

/-- Boundary triples supplement exhaustive widths zero, one and two. -/
def orderWordSamples (width : Nat) : List (List Int) :=
  if width ≤ 2 then
    (List.range (2 ^ width)).flatMap fun a =>
      (List.range (2 ^ width)).flatMap fun b =>
        (List.range (2 ^ width)).map fun c => [a,b,c]
  else
    let modulus : Int := 2 ^ width
    [[0,0,0],[0,1,modulus-1],[1,0,modulus-1],[modulus-1,0,1],
     [modulus/2,0,modulus-1],[modulus-1,modulus/2,1],[1,modulus-1,0],[3,2,1]]

#eval show IO Unit from do
  for rule in allRules do
    IO.println s!"ORDER_TREE key={rule.key} lhs={orderGraphTree rule.lhs} | rhs={orderGraphTree rule.rhs}"
    for track in ["integer","real","unsigned_all_widths","signed_all_widths"] do
      IO.println s!"ORDER_PROFILE track={track} key={rule.key}"
  let mut sample := 0
  for a in [-2,-1,0,1,2] do
    for b in [-2,-1,0,1,2] do
      for c in [-2,-1,0,1,2] do
        orderRows "integer" 0 sample id [a,b,c] id
        sample := sample + 1
  for signed in [false,true] do
    for width in [0,1,2,4,8] do
      for values in orderWordSamples width do
        orderRows (if signed then "signed" else "unsigned") width sample
          (Word.decode (signed := signed) (width := width)) values
          (fun n => (⟨BitVec.ofInt width n⟩ : Word signed width))
        sample := sample + 1
  let nan : Binary32 := ExecFloat.Binary.ofNatBits 0x7fc00000
  let zero : Binary32 := ExecFloat.Binary.ofNatBits 0
  let negZero : Binary32 := ExecFloat.Binary.ofNatBits 0x80000000
  IO.println s!"ORDER_IEEE nan_eq={ExecFloat.compareEqual nan nan} nan_le={ExecFloat.compareLessEqual nan nan} nan_ge={ExecFloat.compareGreaterEqual nan nan} zeros_equal={ExecFloat.compareEqual zero negZero} zeros_bits_equal={decide (zero = negZero)}"
