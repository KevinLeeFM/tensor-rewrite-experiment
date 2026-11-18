import ClampSpec
namespace RevisedBenchmark.ClampGuard
theorem point (b : Bool) (lo x hi : Int) :
    old b lo x hi = clipped lo x hi ↔ lo ≤ hi := by
  cases b <;> simp [old, clipped] <;> omega
theorem domain : Domain := by
  intro I lo x hi b
  constructor
  · intro eq i
    exact (point b _ _ _).mp (congrFun eq i)
  · intro bounds
    funext i
    exact (point b _ _ _).mpr (bounds i)
theorem refuted : ¬ Goal := by
  intro h
  have bound := (domain Unit (fun _ => 2) (fun _ => 0) (fun _ => 1) false).mp
    (h Unit _ _ _ false) ()
  omega
#print axioms domain
#print axioms refuted
end RevisedBenchmark.ClampGuard
