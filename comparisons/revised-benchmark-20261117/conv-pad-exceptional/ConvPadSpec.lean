import TensorRewrite.Pilot.Float32Exceptional

set_option autoImplicit false
namespace RevisedBenchmark.ConvPad
open TensorRewrite.Pilot.Float32Exceptional

/-- Closed binary32 observation fragment. All NaN payloads have one observation. -/
inductive V where | zero | posInf | nan deriving DecidableEq, Repr, Inhabited
def V.bits : V → Bits
  | .zero => 0#32 | .posInf => 0x7f800000#32 | .nan => 0x7fc00000#32

def add : V → V → V
  | .nan, _ | _, .nan => .nan
  | .posInf, _ | _, .posInf => .posInf
  | .zero, .zero => .zero

def mul : V → V → V
  | .zero, .zero => .zero
  | .posInf, .posInf => .posInf
  | _, _ => .nan

/-- Insert interior holes only between entries. -/
def interior (gap : Nat) : List V → List V
  | [] => []
  | [v] => [v]
  | v::u::vs => v :: List.replicate gap .zero ++ interior gap (u::vs)

/-- All extents here are static, with stride one, no reversal or input dilation. -/
def conv (input kernel : List V) (low high : Nat) (dilation : Nat) : List V :=
  let span := if kernel.isEmpty then 0 else (kernel.length-1)*dilation+1
  (List.range (low + input.length + high + 1 - span)).map fun q =>
    (List.range kernel.length).foldl (fun acc k =>
      if low ≤ q + k*dilation then
        match input[q+k*dilation-low]? with
        | some x => add acc (mul x kernel[k]!)
        | none => acc
      else acc) .zero

/-- Convert materialized left/right input padding to implicit window edges. -/
def InputLaw : Prop := ∀ (input kernel : List V) (lo hi : Nat),
  input ≠ [] → kernel ≠ [] →
  conv (List.replicate lo .zero ++ input ++ List.replicate hi .zero) kernel 0 0 1 =
    conv input kernel lo hi 1

/-- Convert materialized filter holes to the corresponding window dilation. -/
def FilterLaw : Prop := ∀ (input kernel : List V) (gap : Nat),
  input ≠ [] → kernel ≠ [] →
  conv input (interior gap kernel) 0 0 1 = conv input kernel 0 0 (gap+1)

end RevisedBenchmark.ConvPad
