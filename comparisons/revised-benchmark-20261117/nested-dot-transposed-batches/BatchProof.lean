import BatchSpec
namespace RevisedBenchmark.BatchDot
open NestedDot

def coeff : Nat → Nat
  | 0 => 8388608 | 1 | 2 => 1 | _ => 0

theorem refuted : (¬ Goal true) ∧ (¬ Goal false) := by
  constructor
  · intro h
    have bad := h 3 3 4 1 4 1 (by decide) (by decide) (by decide)
      (fun x => loadMat fun _ _ => if x = 1 then 3 else 0) (fun _ _ => loadMat fun _ t => coeff t)
      (fun z => loadMat fun _ _ => if z = 2 then 1 else 0) 1 2 0 0 25165832 25165830
      (by decide) (by decide)
    exact (by decide : 25165832 ≠ 25165830) bad
  · intro h
    have bad := h 3 3 1 4 1 4 (by decide) (by decide) (by decide)
      (fun x => loadMat fun _ _ => if x = 1 then 1 else 0) (fun _ _ => loadMat fun t _ => coeff t)
      (fun z => loadMat fun _ _ => if z = 2 then 3 else 0) 1 2 0 0 25165832 25165830
      (by decide) (by decide)
    exact (by decide : 25165832 ≠ 25165830) bad
#print axioms refuted
end RevisedBenchmark.BatchDot
