import MinMaxSpec
set_option autoImplicit false
namespace RevisedBenchmark.MinMax

private theorem uniformFold {I : Type} (rs : List I) (op : Kind) (v : Int) :
    rs.foldl (fun a _ => combine op a v) v = v := by
  induction rs with
  | nil => rfl
  | cons i rest ih =>
    simp only [List.foldl_cons]
    have idem : combine op v v = v := by cases op <;> simp [combine]
    rwa [idem]

theorem verified (op : Kind) : Case op := by
  constructor
  · intro g I v
    funext r i
    exact uniformFold (List.finRange g) op v
  · intro g k C v
    funext r i
    exact uniformFold (List.finRange g) op v

example : Case .minimum := verified .minimum
example : Case .maximum := verified .maximum
#print axioms verified
end RevisedBenchmark.MinMax
