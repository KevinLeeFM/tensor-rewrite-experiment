import ZeroSpec
namespace RevisedBenchmark.PadZ
open RevisedBenchmark.NegatedReduction

/-- Sign of a zero-valued F16 or F32 input after the optional F16→F32 widen. -/
def stored (viaHalf sign : Bool) :=
  if viaHalf then (if sign then 0x8000#16 else 0#16).msb
  else (bits sign).msb

def width (combined : Bool) := if combined then 2 else 3
def padded (c h : Bool) (x : Fin 2 → Bool) (a j k : Int) : Option Bool := do
  if a < 0 ∨ a ≥ width c ∨ j < 0 ∨ j ≥ (if c then 3 else 1) ∨ k ≠ 0 then none
  else
    let pos := if c then a else a-1
    if hp : 0 ≤ pos ∧ pos.toNat < 2 then
      if c && j != 1 then some false else some (stored h (x ⟨pos.toNat,hp.2⟩))
    else some false

def old (c h : Bool) (x : Fin 2 → Bool) (a : Fin (width c)) (j k : Fin 2) :=
  let entries := (List.range (if c then 4 else 2)).flatMap fun u =>
    (List.range 2).filterMap fun v => padded c h x a.val
      ((j.val : Int) + u - (if c then 2 else 1)) ((k.val : Int) + v - 1)
  bits (entries.foldl plus false)

def broadcasted (c h : Bool) (x : Fin 2 → Bool) (a : Fin (width c)) :=
  if hc : c = true then bits (stored h (x ⟨a.val,by simpa [width, hc] using a.isLt⟩))
  else bits ((padded false h x a.val 0 0).getD false)

def Claim (c h : Bool) := ∀ (x : Fin 2 → Bool) (a : Fin (width c)) (j k : Fin 2),
  old c h x a j k = broadcasted c h x a
end RevisedBenchmark.PadZ
