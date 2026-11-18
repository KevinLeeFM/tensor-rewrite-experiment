import SinkSpec
namespace RevisedBenchmark.SinkMixed
def expandProject {r q : Nat} {s : Fin r → Nat} {t : Fin q → Nat}
    (axis : Fin r → Fin q) (fit : ∀ i, s i = 1 ∨ t (axis i) = s i) (o : Coord t) : Coord s :=
  fun i => if unit : s i = 1 then ⟨0, by omega⟩
           else Fin.cast ((fit i).resolve_left unit) (o (axis i))
def ExpandedGoal : Prop := ∀ {r q n : Nat} {s : Fin r → Nat} {t : Fin q → Nat}
    (axis : Fin r → Fin q) (_ordered : ∀ i j, i < j → axis i < axis j)
    (fit : ∀ i, s i = 1 ∨ t (axis i) = s i) (types : Fin n → Type) (β : Type)
    (args : (k : Fin n) → Arg (Coord s) (types k))
    (user : ((k : Fin n) → types k) → β),
    (fun o => user (fun k => before (expandProject axis fit) (args k) o)) =
      (fun o => (fun x => user (fun k => after (args k) x)) (expandProject axis fit o))
end RevisedBenchmark.SinkMixed
