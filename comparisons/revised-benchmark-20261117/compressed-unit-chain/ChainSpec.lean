import TensorRewrite.Pilot.Permutation
namespace CompressedChain
open TensorRewrite.Pilot
inductive Frame (n : Nat)
| plain | unit (axis : Fin (n+1))
deriving DecidableEq

def rank : Frame n → Nat | .plain => n | .unit _ => n+1
def ins (u : Fin (n+1)) (i : Fin n) : Fin (n+1) :=
  ⟨if i.val < u.val then i.val else i.val+1, by split <;> omega⟩
def del (u j : Fin (n+1)) (h : j ≠ u) : Fin n :=
  ⟨if u.val < j.val then j.val-1 else j.val, by
    have : j.val ≠ u.val := fun e => h (Fin.ext e)
    split <;> omega⟩
theorem ins_ne (u : Fin (n+1)) (i : Fin n) : ins u i ≠ u := by
  intro h
  have := congrArg Fin.val h
  simp only [ins] at this
  split at this <;> omega
def slot : (s : Frame n) → Fin n → Fin (rank s)
| .plain => id | .unit u => ins u
abbrev Digits (s : Frame n) := Fin (rank s) → Nat
def expand : (s : Frame n) → (Fin n → Nat) → Digits s
| .plain, f => f
| .unit u, f => fun j => if h : j=u then 0 else f (del u j h)
def validUnit : (s : Frame n) → Digits s → Prop
| .plain, _ => True | .unit u, z => z u = 0
inductive Step (n : Nat) : Frame n → Frame n → Type
| plainT (p : AxisPermutation n) : Step n .plain .plain
| unitT (u v : Fin (n+1)) (p : AxisPermutation (n+1)) (matched : p.outputToInput v = u) :
    Step n (.unit u) (.unit v)
| edit (s t : Frame n) : Step n s t

def pull : Step n s t → Digits t → Digits s
| .plainT p, y => y ∘ p.inputToOutput
| .unitT _ _ p _, y => y ∘ p.inputToOutput
| .edit s t, y => expand s (y ∘ slot t)
def eff : Step n s t → Fin n → Fin n
| .plainT p, i => p.outputToInput i
| .unitT u v p h, i => del u (p.outputToInput (ins v i)) (by
    intro h'
    have e := congrArg p.inputToOutput (h'.trans h.symm)
    rw [p.input_output, p.input_output] at e
    exact ins_ne v i e)
| .edit _ _, i => i

inductive Chain (n : Nat) : Frame n → Frame n → Type
| start (s : Frame n) : Chain n s s
| snoc (c : Chain n s t) (op : Step n t u) : Chain n s u
def total : Chain n s t → Fin n → Fin n
| .start _, i => i | .snoc c op, i => total c (eff op i)
def back : Chain n s t → Digits t → Digits s
| .start _, y => y | .snoc c op, y => back c (pull op y)

def pairs (s : Frame n) (w : Fin n → Nat) (y : Digits s) : List (Nat × Nat) :=
  let live := List.ofFn (fun i => (w i, y (slot s i)))
  match s, y with
  | .plain, _ => live
  | .unit u, z => live.insertIdx u.val (1,z u)
def ordinal (xs : List (Nat × Nat)) (a : Nat) := xs.foldl (fun k x => k*x.1+x.2) a

def StepGate := ∀ {n} {s t : Frame n} (op : Step n s t) y i,
  pull op y (slot s (eff op i)) = y (slot t i)
def EditGate := ∀ {n} (s t : Frame n) w y, validUnit t y →
  ordinal (pairs s w (pull (.edit s t) y)) 0 = ordinal (pairs t w y) 0
def ChainGate := ∀ {n} {s : Frame n} (c : Chain n s s), (∀ i, total c i = i) →
  ∀ y, validUnit s y → ∀ (α : Type) (data : Digits s → α), data (back c y) = data y
end CompressedChain
