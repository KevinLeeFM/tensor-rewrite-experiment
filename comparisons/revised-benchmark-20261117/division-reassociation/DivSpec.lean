import Std
namespace RevisedBenchmark.Division
/-- Observation on the closed positive-power-of-two binary32 fragment. -/
inductive Value where
  | zero | finite (exponent : Int) | infinity | nan
deriving DecidableEq, Repr
open Value
def quantize (e : Int) : Value := if e < -149 then zero else if 127 < e then infinity else finite e
def mul : Value → Value → Value
  | nan, _ | _, nan | zero, infinity | infinity, zero => nan
  | zero, _ | _, zero => zero
  | infinity, _ | _, infinity => infinity
  | finite a, finite b => quantize (a + b)
def div : Value → Value → Value
  | nan, _ | _, nan | zero, zero | infinity, infinity => nan
  | _, zero | infinity, _ => infinity
  | zero, _ | _, infinity => zero
  | finite a, finite b => quantize (a - b)
def legal (e : Int) : Prop := -149 ≤ e ∧ e ≤ 127
def Reciprocal := ∀ a b : Int, legal a → legal b →
  div (finite a) (finite b) = mul (finite a) (div (finite 0) (finite b))
def Fractions := ∀ a b c d : Int, legal a → legal b → legal c → legal d →
  div (div (finite a) (finite b)) (div (finite c) (finite d)) =
    div (mul (finite a) (finite d)) (mul (finite b) (finite c))
def Numerator := ∀ a b c : Int, legal a → legal b → legal c →
  div (div (finite a) (finite b)) (finite c) = div (finite a) (mul (finite b) (finite c))
def Denominator := ∀ a b c : Int, legal a → legal b → legal c →
  div (finite a) (div (finite b) (finite c)) = div (mul (finite a) (finite c)) (finite b)
end RevisedBenchmark.Division
