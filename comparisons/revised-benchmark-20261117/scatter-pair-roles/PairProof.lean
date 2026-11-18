import PairSpec
namespace RevisedBenchmark.ScatterPair
private theorem call_add (f : Form) (hf : ordinary f = true) (a b : Int) :
    call f a b = a+b := by cases f <;> simp_all [ordinary,call, Int.add_comm]

def probe (concat : Bool) (l r : Form) : Bool :=
  let x := fun _ : Fin 3 => (1 : Int)
  let y := fun _ : Fin 3 => (2 : Int)
  let orig := before l r x y 0 1 3 5
  let repl := after concat l r x y 0 1 3 5
  (orig 0 == repl 0) && (orig 1 == repl 1)

private theorem probe_pass (c : Bool) (l r : Form) :
    probe c l r = (ordinary l && ordinary r) := by
  cases c <;> cases l <;> cases r <;> decide

theorem criterion (c : Bool) (l r : Form) :
    Case c l r ↔ ordinary l = true ∧ ordinary r = true := by
  constructor
  · intro h
    have eq := h 3 (by decide) (fun _ => 1) (fun _ => 2) 0 1 (by decide) 3 5
    have pass : probe c l r = true := by simp [probe,eq]
    simpa [probe_pass] using pass
  · rintro ⟨hl,hr⟩ n _ x y p q hd u v
    funext i
    by_cases a : i=p <;> by_cases b : i=q <;> cases c <;>
      simp_all [before,after,write,call_add l hl,call_add r hr] <;> omega
#print axioms criterion
end RevisedBenchmark.ScatterPair
