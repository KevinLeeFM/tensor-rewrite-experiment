import ChainSpec
namespace CompressedChain

theorem ins_del (u j : Fin (n+1)) (h : j≠u) : ins u (del u j h) = j := by
  apply Fin.ext
  have : j.val ≠ u.val := fun e => h (Fin.ext e)
  simp only [ins, del]
  split <;> split <;> omega
theorem del_ins (u : Fin (n+1)) (i : Fin n) : del u (ins u i) (ins_ne u i) = i := by
  apply Fin.ext
  simp only [del, ins]
  split <;> split <;> omega
theorem expand_slot (s : Frame n) (f : Fin n → Nat) (i : Fin n) :
    expand s f (slot s i) = f i := by
  cases s with
  | plain => rfl
  | unit u => simp [slot, expand, ins_ne, del_ins]

theorem step_verified : StepGate := by
  intro n s t op y i
  cases op with
  | plainT p => exact congrArg y (p.input_output i)
  | unitT u v p h =>
    simp only [slot, eff, pull, ins_del]
    exact congrArg y (p.input_output _)
  | edit s t => exact expand_slot s _ i

theorem unit_pull {s t : Frame n} (op : Step n s t) (y : Digits t) (hy : validUnit t y) :
    validUnit s (pull op y) := by
  cases op with
  | plainT => trivial
  | unitT u v p h =>
    have e := congrArg p.inputToOutput h
    rw [p.input_output] at e
    exact (congrArg y e.symm).trans hy
  | edit s t => cases s <;> simp [validUnit, pull, expand]

theorem fold_unit (xs : List (Nat × Nat)) (i k : Nat) :
    ordinal (xs.insertIdx i (1,0)) k = ordinal xs k := by
  induction xs generalizing i k with
  | nil => cases i <;> simp [ordinal, List.insertIdx]
  | cons x xs ih =>
    cases i with
    | zero => simp [ordinal, List.insertIdx]
    | succ i => exact ih i (k*x.1+x.2)
theorem compact_ord (s : Frame n) (w : Fin n → Nat) (z : Digits s) (h : validUnit s z) :
    ordinal (pairs s w z) 0 = ordinal (List.ofFn (fun i => (w i,z (slot s i)))) 0 := by
  cases s with
  | plain => rfl
  | unit u => simpa only [pairs, (show z u = 0 from h)] using
      fold_unit (List.ofFn (fun i => (w i,z (slot (.unit u) i)))) u.val 0
theorem edit_verified : EditGate := by
  intro n s t w y hy
  rw [compact_ord _ _ _ (unit_pull _ _ hy), compact_ord _ _ _ hy]
  simp [pull, expand_slot]

theorem chain_slot {s t : Frame n} (c : Chain n s t) (y : Digits t) (i : Fin n) :
    back c y (slot s (total c i)) = y (slot t i) := by
  induction c generalizing i with
  | start => rfl
  | snoc c op ih => exact (ih (pull op y) (eff op i)).trans (step_verified op y i)
theorem chain_unit {s t : Frame n} (c : Chain n s t) (y : Digits t) (h : validUnit t y) :
    validUnit s (back c y) := by
  induction c with
  | start => exact h
  | snoc c op ih => exact ih _ (unit_pull op y h)
theorem digits_ext (s : Frame n) (x y : Digits s) (hx : validUnit s x) (hy : validUnit s y)
    (h : ∀ i, x (slot s i) = y (slot s i)) : x=y := by
  funext j
  cases s with
  | plain => exact h j
  | unit u =>
    by_cases e : j = u
    · subst j; exact hx.trans hy.symm
    · have hj := h (del u j e)
      change x (ins u (del u j e)) = y (ins u (del u j e)) at hj
      exact (congrArg x (ins_del u j e)).symm.trans (hj.trans (congrArg y (ins_del u j e)))
theorem chain_verified : ChainGate := by
  intro n s c hid y hy α data
  apply congrArg data
  apply digits_ext _ _ _ (chain_unit c y hy) hy
  intro i
  simpa [hid] using chain_slot c y i
#print axioms step_verified
#print axioms edit_verified
#print axioms chain_verified
end CompressedChain
