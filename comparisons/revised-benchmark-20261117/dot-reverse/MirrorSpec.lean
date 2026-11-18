import TensorRewrite.Pilot.Indexing
set_option autoImplicit false
namespace RevisedBenchmark.DotMirror
open TensorRewrite.Pilot

/-- Paired contracting axes in dimension-number order, with a flag on each moved axis. -/
abbrev Axes := List (Nat × Bool)
def Coord : Axes → Type
  | [] => Unit
  | (k,_) :: ds => Fin k × Coord ds
def mirror : (ds : Axes) → Coord ds → Coord ds
  | [], _ => ()
  | (_,flip) :: ds, (i,t) => (if flip then i.rev else i, mirror ds t)
def sumAt : (ds : Axes) → (Coord ds → Int) → Int
  | [], f => f ()
  | (_,_) :: ds, f => (List.ofFn (fun i => sumAt ds (fun t => f (i,t)))).sum
def times (swapped : Bool) (a b : Int) : Int := if swapped then b*a else a*b

def Case : Prop := ∀ {br lr : Nat} (b : Shape br) (l : Shape lr) (R : Type)
    (keepB : Fin br → Bool) (keepL : Fin lr → Bool) (ds : Axes) (swapped : Bool)
    (from : Index b → Index l → Coord ds → Int) (other : Index b → R → Coord ds → Int),
  (fun (batch : Index b) (i : Index l) (j : R) =>
    sumAt ds (fun k => times swapped (from (Tensor.reverseIndex keepB batch)
      (Tensor.reverseIndex keepL i) (mirror ds k)) (other batch j k))) =
  (fun batch i j => sumAt ds (fun k => times swapped (from (Tensor.reverseIndex keepB batch)
      (Tensor.reverseIndex keepL i) k) (other batch j (mirror ds k))))
end RevisedBenchmark.DotMirror
