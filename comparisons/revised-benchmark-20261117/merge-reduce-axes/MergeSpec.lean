import Std
namespace RevisedBenchmark.MergeAxes

abbrev Tensor := Nat → Nat → Nat → Int
def sumOver (xs : List Nat) (f : Nat → Int) := (xs.map f).sum
def original (firstRow : Bool) (m n : Nat) (x : Tensor) (k : Nat) (seed : Int) :=
  if firstRow then
    seed + sumOver (List.range n) (fun j =>
      seed + sumOver (List.range m) (fun i => x i j k))
  else
    seed + sumOver (List.range m) (fun i =>
      seed + sumOver (List.range n) (fun j => x i j k))

def merged (m n : Nat) (x : Tensor) (k : Nat) (seed : Int) :=
  let fiber := (List.range m).flatMap fun i => (List.range n).map fun j => (i,j)
  seed + (fiber.map fun p => x p.1 p.2 k).sum

/-- With one axis removed, source increments a reduced axis at or after the removed one. -/
def lifted (inner shortened : Nat) := if shortened ≥ inner then shortened+1 else shortened
def mergedDims (firstRow : Bool) :=
  let inner := if firstRow then 0 else 1
  let outer := lifted inner 0
  [min inner outer, max inner outer]

def Goal := ∀ (firstRow : Bool) (m n keep : Nat) (x : Tensor) (k : Fin keep) (seed : Int),
  mergedDims firstRow = [0,1] ∧
  original firstRow m n x k seed =
    merged m n x k seed + (if firstRow then (n : Int) else (m : Int)) * seed
end RevisedBenchmark.MergeAxes
