import RemoveProof
set_option autoImplicit false
open TensorRewrite.Pilot RevisedBenchmark.DotSwap RevisedBenchmark.RemoveInputTransposes

private def p : AxisPermutation 3 := ⟨(·+1), (·+2), by decide, by decide⟩
private def d : AxisPermutation 3 := ⟨Fin.rev, Fin.rev, Fin.rev_rev, Fin.rev_rev⟩
private def s : Shape 3 := fun _ => 3
private def q : Index (fun a => s (p.outputToInput (d.outputToInput a))) := id
private def a (v : Fin 3 → Nat) (i t : Fin 2) : Int := (v 0 : Int) + 3*i.val + t.val
private def c (v : Fin 3 → Nat) (j t : Fin 2) : Int := 2*(v 1 : Int) + 5*j.val - t.val
private def u := operandBatch (p.comp d) (fun t => (q t).val)
private def wrong := operandBatch (d.comp p) (fun t => (q t).val)
private def orig := dot 2 d d (flipLast (pull p a)) (pull p c) (fun t => (q t).val) 0 1
private def replaced := dot 2 (.identity 3) (.identity 3) c (flipLast a)

example : orig = replaced u 1 0 := swapVerified s p d 2 2 2 a c q 0 1
example : orig ≠ replaced wrong 1 0 := by decide
example : orig ≠ replaced u 0 1 := by decide
example : dot 2 d d (pull p a) (flipLast (pull p c)) (fun t => (q t).val) 0 1 =
    dot 2 (.identity 3) (.identity 3) a (flipLast c) u 0 1 :=
  keepVerified s p d 2 2 2 a c q 0 1
example : dot 0 (.identity 0) (.identity 0) (fun _ (_ : Fin 3) _ => (7 : Int))
    (fun _ (_ : Fin 4) _ => -1) (fun _ => 0) 2 3 = 0 := by decide

/-- Unlike the equal-extent mutation above, an incorrect batch ordering can even change shape. -/
private def varied : Shape 3 := fun x => x.val + 2
example : varied (p.outputToInput (d.outputToInput 0)) ≠
    varied (d.outputToInput (p.outputToInput 0)) := by decide
