import Std
namespace RevisedBenchmark.PrefixPipeline
inductive Target | s32 | s64 deriving DecidableEq
def width : Target → Nat | .s32 => 32 | .s64 => 64
inductive Cast | s8 | u8 | s32 | s64 deriving DecidableEq
def convert (c : Cast) (x : Int) : Int :=
  match c with
  | .s8 => (BitVec.ofInt 8 x).toInt
  | .u8 => Int.ofNat (BitVec.ofInt 8 x).toNat
  | .s32 => (BitVec.ofInt 32 x).toInt
  | .s64 => (BitVec.ofInt 64 x).toInt
inductive Stage (n : Nat) where
  | cast (c : Cast)
  | view (pull : Fin n → Fin n)

/-- Stages are in source operand walk order, outermost first. -/
def data {n : Nat} : List (Stage n) → Int → Fin n → Int
  | [], literal, _ => literal
  | .cast c :: tail, literal, i => convert c (data tail literal i)
  | .view pull :: tail, literal, i => data tail literal (pull i)

def casts {n : Nat} (ss : List (Stage n)) := ss.filterMap fun s =>
  match s with | .cast c => some c | .view _ => none
def scalar {n : Nat} (ss : List (Stage n)) (v : Int) :=
  (casts ss).reverse.foldl (fun acc c => convert c acc) v

def old (t : Target) {n : Nat} (ss : List (Stage n)) (v : Int) (r : Fin n) :=
  ((List.finRange (r.val+1)).map fun i =>
    BitVec.ofInt (width t) (data ss v ⟨i.val, by have := i.isLt; omega⟩)).foldl (·+·) 0
def newValue (t : Target) {n : Nat} (ss : List (Stage n)) (v : Int) (r : Fin n) :=
  let iota := BitVec.ofNat (width t) r.val
  (BitVec.ofInt (width t) (scalar ss v)) * (iota+1)

def Goal := ∀ t n, 1 < n → ∀ (ss : List (Stage n)) v r,
  old t ss v r = newValue t ss v r
end RevisedBenchmark.PrefixPipeline
