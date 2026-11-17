module
public import DynamicSpec
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.DynamicSort

/-- Characterize exactly which fixed descriptors make the raw-guarded rule
    valid for every runtime input in the one-array and lockstep pair models. -/
def Classification : Prop :=
  ∀ d : Dim,
   ((∀ xs : List Nat, d.admits xs.length → forward d →
       xs.mergeSort (fun a b => decide (a < b)) = xs) ↔ d ≠ .unbounded) ∧
   ((∀ rows : List (Nat × Bool), d.admits rows.length → forward d →
       (rows.mergeSort (fun a b => decide (a.1 < b.1))).map Prod.fst = rows.map Prod.fst ∧
       (rows.mergeSort (fun a b => decide (a.1 < b.1))).map Prod.snd = rows.map Prod.snd) ↔
       d ≠ .unbounded)
end RevisedBenchmark.DynamicSort
