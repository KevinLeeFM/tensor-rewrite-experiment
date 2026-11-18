import Std
namespace RevisedBenchmark.ScatterPair
inductive Form where | cc | cu | uc | uu deriving DecidableEq, Repr
def call : Form → Int → Int → Int
  | .cc, c, _ => c+c | .cu, c, u => c+u | .uc, c, u => u+c | .uu, _, u => u+u
def ordinary : Form → Bool | .cu | .uc => true | _ => false

def write {n : Nat} (r : Form) (x : Fin n → Int) (p : Fin n) (u : Int) (i : Fin n) :=
  if i = p then call r (x i) u else x i

def before {n : Nat} (l r : Form) (x y : Fin n → Int) (p q : Fin n) (u v : Int) (i : Fin n) :=
  write l x p u i + write r y q v i

def after {n : Nat} (concat : Bool) (l r : Form) (x y : Fin n → Int) (p q : Fin n) (u v : Int) :=
  let base := fun i => x i + y i
  if concat then write l (write l base p u) q v else write l (write r base q v) p u

def Case (concat : Bool) (l r : Form) := ∀ n, 2 < n →
  ∀ (x y : Fin n → Int) (p q : Fin n), p ≠ q → ∀ u v,
    before l r x y p q u v = after concat l r x y p q u v
end RevisedBenchmark.ScatterPair
