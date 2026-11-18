import Std
set_option autoImplicit false
namespace RevisedBenchmark.DotConcat

/-- A list of K column slices. Each slice has one entry for every M coordinate. -/
abbrev Columns (m : Nat) := List (Fin m → Int)
def times (swapped : Bool) (x y : Int) : Int := if swapped then y*x else x*y

/-- Ordinary dot at a pair of free coordinates. The constant is read from position zero. -/
def dotAt {m : Nat} (swapped : Bool) (i : Fin m) (weights : Nat → Int) : Columns m → Int
  | [] => 0
  | col :: cols => times swapped (col i) (weights 0) +
      dotAt swapped i (fun t => weights (t+1)) cols

/-- Slice the constant at the cumulative length, compute a block dot, then add to the running result. -/
def blockSum {m : Nat} (swapped : Bool) (i : Fin m) (weights : Nat → Int) :
    List (Columns m) → Nat → Int → Int
  | [], _, acc => acc
  | cols :: rest, pos, acc =>
    blockSum swapped i weights rest (pos + cols.length)
      (acc + dotAt swapped i (fun t => weights (pos+t)) cols)

def Case : Prop := ∀ (m n : Nat) (swapped : Bool) (first : Columns m) (rest : List (Columns m))
    (constant : Fin n → Nat → Int),
  (fun (i : Fin m) (j : Fin n) => dotAt swapped i (constant j) (first :: rest).flatten) =
  (fun i j => blockSum swapped i (constant j) (first :: rest) 0 0)
end RevisedBenchmark.DotConcat
