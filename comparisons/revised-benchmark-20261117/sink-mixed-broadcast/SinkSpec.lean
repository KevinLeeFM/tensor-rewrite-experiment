import Std

namespace RevisedBenchmark.SinkMixed

abbrev Coord {r : Nat} (s : Fin r → Nat) := (i : Fin r) → Fin (s i)

inductive Arg (small : Type) (α : Type) where
  | scalar (value : α)
  | array (read : small → α)

def before {S T α : Type} (proj : T → S) (arg : Arg S α) : T → α :=
  match arg with
  | .scalar v => fun _ => v
  | .array a => fun o => a (proj o)

def after {S α : Type} (arg : Arg S α) : S → α :=
  match arg with
  | .scalar v => fun _ => v
  | .array a => a

def project {r q : Nat} {s : Fin r → Nat} {t : Fin q → Nat}
    (axis : Fin r → Fin q) (fit : ∀ i, t (axis i) = s i) (o : Coord t) : Coord s :=
  fun i => Fin.cast (fit i) (o (axis i))

def Goal : Prop := ∀ {r q n : Nat} {s : Fin r → Nat} {t : Fin q → Nat}
    (axis : Fin r → Fin q) (_ordered : ∀ i j, i < j → axis i < axis j)
    (fit : ∀ i, t (axis i) = s i) (types : Fin n → Type) (β : Type)
    (args : (k : Fin n) → Arg (Coord s) (types k))
    (user : ((k : Fin n) → types k) → β),
    (fun o => user (fun k => before (project axis fit) (args k) o)) =
      (fun o => (fun x => user (fun k => after (args k) x)) (project axis fit o))
end RevisedBenchmark.SinkMixed
