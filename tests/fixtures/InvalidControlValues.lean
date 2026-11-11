import TensorRewrite.Theory.ControlValuesCounterexamples

open TensorRewrite.Theory.ControlValues

example : (if compare .gt true false then true else false) = (true && false) := by decide

example : ((7 : Int) - 9) = (9 - 7) := by decide

example : eagerSelect ⟨true, []⟩ ⟨(7 : Nat), []⟩ ⟨9, [3]⟩ = ⟨7, []⟩ := by decide

example : indexedConditional (booleanIndex true) (fun _ => ())
    (fun branch _ => (⟨7, [branch.val]⟩ : Observed Nat)) =
    predicateConditional true () (fun _ => (⟨7, [0]⟩ : Observed Nat))
      () (fun _ => ⟨7, [1]⟩) := by decide
