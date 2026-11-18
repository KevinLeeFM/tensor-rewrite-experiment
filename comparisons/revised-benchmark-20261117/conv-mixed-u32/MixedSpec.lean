module
public import PointProof
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.ConvMixedU32
open ConvPointAxes

inductive Storage | byte | word deriving DecidableEq
def limit : Storage → Nat | .byte => 256 | .word => 4294967296
abbrev Operand (t : Storage) (shape : Coord) := {i : Coord // Fits shape i} → Fin (limit t)

/-- Zero-extension of a byte or identity on a word, expressed in the target U32 carrier. -/
def toResult {t : Storage} {shape : Coord} (x : Operand t shape) : Tensor shape :=
  fun i => (x i).val % 4294967296

/-- The evaluator uses a U64 accumulator, clamps to the U32 range, then stores the result. -/
def evaluated {a b : Storage} (s : Sizes) (l k o : Order) (y : Coord)
    (x : Operand a (lhsShape s l)) (w : Operand b (rhsShape s k)) :=
  (min ((doConv s l k o y (toResult x) (toResult w)) % 18446744073709551616)
    4294967295) % 4294967296

/-- The emitted U32 multiply stores the low word, after widening either byte operand. -/
def emitted {a b : Storage} (s : Sizes) (l k o : Order) (y : Coord)
    (x : Operand a (lhsShape s l)) (w : Operand b (rhsShape s k)) :=
  (product s l k o y (toResult x) (toResult w)) % 4294967296

def Universal (a b : Storage) := ∀ (s : Sizes), Legal s → ∀ (l k o : Order) (y : Coord),
  Fits (outShape s o) y → ∀ (x : Operand a (lhsShape s l)) (w : Operand b (rhsShape s k)),
  evaluated s l k o y x w = emitted s l k o y x w

def Goal := (∀ (a b : Storage) (s : Sizes), Legal s → ∀ (l k o : Order) (y : Coord),
   Fits (outShape s o) y → ∀ (x : Operand a (lhsShape s l)) (w : Operand b (rhsShape s k)),
   let p := product s l k o y (toResult x) (toResult w)
   evaluated s l k o y x w = emitted s l k o y x w ↔
     p < 4294967296 ∨ p % 4294967296 = 4294967295) ∧
  Universal .byte .byte ∧ ¬ Universal .byte .word ∧ ¬ Universal .word .byte
end RevisedBenchmark.ConvMixedU32
