import Std
set_option autoImplicit false
namespace RevisedBenchmark.DotDropUnit

abbrev Shape := List Nat
abbrev Coord := List Nat
/-- Row-major, outermost axis first. Rank zero has one coordinate. -/
def grid : Shape → List Coord
  | [] => [[]]
  | n :: ns => (List.range n).flatMap fun i => (grid ns).map (i :: ·)
def compact (s : Shape) := s.filter (· != 1)
/-- Pull a reduced coordinate back to the old operand. Only valid grid points are read. -/
def expand : Shape → Coord → Coord
  | [], _ => []
  | n :: ns, p => if n = 1 then 0 :: expand ns p
    else p.headD 0 :: expand ns p.tail
/-- Stable physical axis renumbering, applied in descriptor-list order. -/
def remap (s : Shape) (i : Nat) : Option Nat :=
  if s[i]? = some 1 then none else some (compact (s.take i)).length
/-- Ordered paired descriptors and their common legal extents; positions may differ. -/
def descriptorCase : Prop := ∀ (l r : Shape) (pairs : List (Nat × Nat))
  (_ : ∀ p ∈ pairs, ∃ n, l[p.1]? = some n ∧ r[p.2]? = some n),
  ((pairs.map Prod.fst).filterMap (remap l)).zip
    ((pairs.map Prod.snd).filterMap (remap r)) =
    pairs.filterMap (fun (i,j) => (remap l i).bind fun x => (remap r j).map (x, ·))

abbrev Operand := Coord → Coord → Coord → Int
/-- Flattened dense output, in batch/left-free/right-free order. -/
def dotData (b l r k : Shape) (a z : Operand) : List Int :=
  (grid b).flatMap fun t => (grid l).flatMap fun x => (grid r).map fun y =>
    ((grid k).map fun h => a t x h * z t y h).sum
def pull (b f k : Shape) (a : Operand) : Operand :=
  fun t x h => a (expand b t) (expand f x) (expand k h)
abbrev Tensor := Shape × List Int
def original (b l r k : Shape) (a z : Operand) : Tensor :=
  (b ++ l ++ r, dotData b l r k a z)
def replacement (b l r k : Shape) (a z : Operand) : Tensor :=
  let out := compact b ++ compact l ++ compact r
  let data := dotData (compact b) (compact l) (compact r) (compact k)
    (pull b l k a) (pull b r k z)
  if out = b ++ l ++ r then (out, data) else (b ++ l ++ r, data)
/-- One optimization, both output branches, including empty contractions. -/
def Case : Prop := descriptorCase ∧ ∀ (b l r k : Shape) (a z : Operand),
  1 ∈ b ++ l ++ r ++ k → original b l r k a z = replacement b l r k a z

end RevisedBenchmark.DotDropUnit
