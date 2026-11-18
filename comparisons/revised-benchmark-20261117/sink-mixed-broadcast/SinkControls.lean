import SinkProof
namespace RevisedBenchmark.SinkMixed
def small (_ : Fin 1) := 2
def large (_ : Fin 2) := 2
def second (_ : Fin 1) : Fin 2 := 1
def first (_ : Fin 1) : Fin 2 := 0
def ix : Coord large := fun i => if i = 1 then (1 : Fin 2) else (0 : Fin 2)
def read : Arg (Coord small) Nat := .array (fun i => (i 0).val + 7)
def keep : Arg (Coord small) Bool := .scalar true
def inner (i : Coord small) : Nat := if after keep i then after read i else 99
example : (if before (project second (fun _ => rfl)) keep ix then
    before (project second (fun _ => rfl)) read ix else 99) = 8 := by decide
example : inner (project second (fun _ => rfl) ix) = 8 := by decide
example : inner (project first (fun _ => rfl) ix) ≠ 8 := by decide
example (o : Coord (fun _ : Fin 1 => 0)) : False := Fin.elim0 (o 0)
#check (verified : Goal)
end RevisedBenchmark.SinkMixed
