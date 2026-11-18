import Std
set_option autoImplicit false
namespace RevisedBenchmark.TupleExpand

/-- A single literal can contain arbitrary tagged leaf objects and ordered tuple fields. -/
inductive Lit (α : Type) where
  | atom (v : α)
  | tuple (n : Nat) (child : Fin n → Lit α)

/-- The constructed expression has one constant per leaf and explicit tuple operand lists. -/
inductive Expr (α : Type) where
  | const (v : α)
  | make (operands : List (Expr α))

/-- A valid position observes either its complete atomic literal or a tuple arity. -/
inductive Obs (α : Type) where
  | atom (v : α)
  | arity (n : Nat)
deriving DecidableEq

def expand {α : Type} : Lit α → Expr α
  | .atom v => .const v
  | .tuple n child => .make (List.ofFn (fun i : Fin n => expand (child i)))

def literalAt {α : Type} : List Nat → Lit α → Option (Obs α)
  | [], .atom v => some (.atom v)
  | [], .tuple n _ => some (.arity n)
  | _::_, .atom _ => none
  | k::ks, .tuple n c => if h : k < n then literalAt ks (c ⟨k,h⟩) else none

def expressionAt {α : Type} : List Nat → Expr α → Option (Obs α)
  | [], .const v => some (.atom v)
  | [], .make xs => some (.arity xs.length)
  | _::_, .const _ => none
  | k::ks, .make xs => xs[k]?.bind (expressionAt ks)

def Case := ∀ {α : Type} (n : Nat) (child : Fin n → Lit α) (path : List Nat),
  literalAt path (.tuple n child) = expressionAt path (expand (.tuple n child))
end RevisedBenchmark.TupleExpand
