import Std
namespace RevisedBenchmark.LiteralConvert

abbrev ArrayValue (dims : List Nat) (α : Type) := Fin dims.prod → α

inductive Expr (A B : Type)
  | literal (result : B)
  | convert (operand : A)

def eval (convertLiteral : A → Option B) : Expr A B → Option B
  | .literal result => some result
  | .convert operand => convertLiteral operand

def foldConstant (convertLiteral : A → Option B) (operand : A) : Option (Expr A B) :=
  (convertLiteral operand).map Expr.literal

def FoldingGoal := ∀ (dims : List Nat) (α β : Type)
    (convertLiteral : ArrayValue dims α → Option (ArrayValue dims β)) (v : ArrayValue dims α),
    (foldConstant convertLiteral v).bind (eval convertLiteral) =
      eval convertLiteral (.convert v)

def cloneArray {dims : List Nat} (v : ArrayValue dims α) : ArrayValue dims α :=
  fun i => v i

def IdentityGoal := ∀ (dims : List Nat) (α : Type) (v : ArrayValue dims α),
    eval (fun x => some (cloneArray x)) (.convert v) =
      eval (fun x => some (cloneArray x)) (.literal v)
end RevisedBenchmark.LiteralConvert
