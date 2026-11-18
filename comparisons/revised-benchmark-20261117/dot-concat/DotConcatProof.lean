import DotConcatSpec
set_option autoImplicit false
namespace RevisedBenchmark.DotConcat
private theorem appendDot {m : Nat} (s : Bool) (i : Fin m) (xs ys : Columns m)
    (w : Nat → Int) (p : Nat) :
    dotAt s i (fun t => w (p+t)) (xs ++ ys) =
      dotAt s i (fun t => w (p+t)) xs + dotAt s i (fun t => w (p+xs.length+t)) ys := by
  induction xs generalizing p with
  | nil => simp [dotAt]
  | cons x xs ih =>
    simpa [dotAt, Nat.add_assoc, Nat.add_comm, Nat.add_left_comm, Int.add_assoc]
      using congrArg (fun a => times s (x i) (w p) + a) (ih (p+1))

private theorem collect {m : Nat} (s : Bool) (i : Fin m) (w : Nat → Int)
    (bs : List (Columns m)) (p : Nat) (acc : Int) :
    blockSum s i w bs p acc = acc + dotAt s i (fun t => w (p+t)) bs.flatten := by
  induction bs generalizing p acc with
  | nil => simp [blockSum, dotAt]
  | cons xs rest ih =>
    simp only [blockSum, List.flatten_cons, ih, appendDot]
    omega

theorem verified : Case := by
  intro m n s xs rest c
  funext i j
  rw [collect]
  simp
/-- Results depend only on legal positions in the finite constant operand. -/
theorem finiteConstant {m : Nat} (s : Bool) (i : Fin m) (xs : Columns m)
    (a b : Nat → Int) (agree : ∀ t, t < xs.length → a t = b t) :
    dotAt s i a xs = dotAt s i b xs := by
  induction xs generalizing a b with
  | nil => rfl
  | cons x xs ih =>
    simp only [dotAt]
    rw [agree 0 (by simp)]
    congr 1
    apply ih
    intro t ht
    apply agree
    simpa using ht
example : Case := verified
#print axioms verified
end RevisedBenchmark.DotConcat
