import Std
namespace RevisedBenchmark.ConvDotOrder

/-- Physical row address of an output ordered [batch,space,channel] or
[space,batch,channel]. All arrays have descending dense layout and one channel. -/
def outputRow (swapped : Bool) (batches sites b s : Nat) :=
  if swapped then s*batches+b else b*sites+s

def conv (sites b s : Nat) (x : Nat → Nat) (w : Nat) :=
  ([(x (b*sites+s))*w] : List Nat).sum
def dot (swapped : Bool) (batches sites b s : Nat) (x : Nat → Nat) (w : Nat) :=
  let row := outputRow swapped batches sites b s
  ((List.range 1).map fun channel => x (row*1+channel)*w).sum

def Case (swapped : Bool) (batches sites : Nat) :=
  ∀ (b : Fin batches) (s : Fin sites) (x : Nat → Nat) (w : Nat),
    conv sites b.val s.val x w = dot swapped batches sites b.val s.val x w
end RevisedBenchmark.ConvDotOrder
