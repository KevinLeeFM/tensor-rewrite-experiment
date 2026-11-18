import NestedSpec
set_option autoImplicit false
namespace RevisedBenchmark.NestedDot

def coeff : Nat → Nat
  | 0 => 8388608 | 1 | 2 => 1 | _ => 0

theorem refuted : (¬ Case true) ∧ (¬ Case false) := by
  constructor
  · intro law
    have bad := law 4 1 4 1 (by decide) (by decide) (by decide)
      (fun _ _ => 3) (fun _ t => coeff t) (fun _ _ => 1) 0 0
      25165832 25165830 (by decide) (by decide)
    exact (by decide : 25165832 ≠ 25165830) bad
  · intro law
    have bad := law 1 4 1 4 (by decide) (by decide) (by decide)
      (fun _ _ => 1) (fun t _ => coeff t) (fun _ _ => 3) 0 0
      25165830 25165832 (by decide) (by decide)
    exact (by decide : 25165830 ≠ 25165832) bad
#print axioms refuted
end RevisedBenchmark.NestedDot
