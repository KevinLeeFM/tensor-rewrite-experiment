import Std
set_option autoImplicit false
namespace RevisedBenchmark.BatchSeed
def sum (n : Nat) (f : Nat → Int) := ((List.range n).map f).sum
abbrev L := Nat → Nat → Nat → Int   -- batch, free, contracting
abbrev R := Nat → Nat → Int         -- batch, contracting
def oldDot (k : Nat) (l : L) (r : R) (b f : Nat) := sum k fun t => l b f t * r b t
def newDot (n k : Nat) (l : L) (r : R) (f : Nat) :=
  sum k fun t => sum n fun b => l b f t * r b t

def Direct := ∀ (n k m : Nat) (z : Int) (l : L) (r : R) (f : Fin m),
  z + sum n (fun b => oldDot k l r b f) = newDot n k l r f
def Residual := ∀ (n k m : Nat) (z : Int) (l : L) (r : R),
  z + sum n (fun b => sum m fun f => oldDot k l r b f) =
    z + sum m (fun f => newDot n k l r f)
end RevisedBenchmark.BatchSeed
