import Std
namespace RevisedBenchmark.NamedMaximum

inductive Op | erf | logistic | tanh deriving DecidableEq, Repr

def fact : Nat → Nat
  | 0 => 1
  | k+1 => (k+1) * fact k
def sum (n : Nat) (f : Nat → Rat) := ((List.range (n+1)).map f).foldl (·+·) 0
def alt (k : Nat) : Rat := if k % 2 = 0 then 1 else -1
def expLo (x : Nat) := sum 20 fun k => (x:Rat)^k / fact k
def expHi (x : Nat) := expLo x + 2 * (x:Rat)^21 / fact 21
def atanSum (d n : Nat) := sum n fun k => alt k / ((2*k+1:Nat):Rat) / (d:Rat)^(2*k+1)
def piLo := 16*atanSum 5 9 - 4*atanSum 239 8
def piHi := 16*atanSum 5 8 - 4*atanSum 239 9
def integralSum (n : Nat) := sum n fun k => alt k / fact k / ((2*k+1:Nat):Rat)
def logisticOfExp (e : Rat) := e/(1+e)
def tanhOfExp (e : Rat) := (e-1)/(e+1)

-- For input one the bounds enclose f(1), or its square for erf. Strict
-- interior midpoints certify the exact rounded result on the [1/2,1) binade.
def certOne (op : Op) (p m : Nat) : Bool := Id.run do
  let s : Nat := 2^(p+1)
  let l := ((2*m:Nat):Rat)/(2*s) - 1/((2*s:Nat):Rat)
  let h := ((2*m+1:Nat):Rat)/(2*s)
  if !(s/2 < m && m < s) then return false
  return match op with
  | .logistic => decide (l < logisticOfExp (expLo 1) ∧ logisticOfExp (expHi 1) < h)
  | .tanh => decide (l < tanhOfExp (expLo 2) ∧ tanhOfExp (expHi 2) < h)
  | .erf => decide (l*l*piHi < 4*(integralSum 13)^2 ∧ 4*(integralSum 12)^2 < h*h*piLo)

def rounds (op : Op) (p x m : Nat) : Bool :=
  match x with
  | 0 => m == (if op == .logistic then 2^p else 0)
  | 1 => certOne op p m
  | _ => false

def Goal (op : Op) := ∀ (x y l r out : Nat),
    rounds op 7 x l = true → rounds op 23 y r = true →
    rounds op 23 (max x y) out = true → max (l*2^16) r = out
end RevisedBenchmark.NamedMaximum
