import MappedSpec
import RadixSpec
set_option autoImplicit false
namespace RevisedBenchmark.ReduceMultiplicity
open ReduceMapped
/-- Here only kept axes belong to x; added and reduced axes are both introduced
by the broadcast. Remove reduced axes from the intermediate coordinate that
retains kept and reduced axes. -/
def eraseReduced : List (Nat × Bool) → List Nat → List Nat
  | [], _ => []
  | (_, true)::t, c => eraseReduced t c.tail
  | (_, false)::t, c => c.headD 0 :: eraseReduced t c.tail

def count : List Axis → Nat
  | [] => 1
  | .kept _::t | .added _::t => count t
  | .reduced n::t => n * count t

def operandReads (ds : List Axis) (out : List Nat) :=
  (reads (dims ds) out).map fun c => eraseReduced (baseDims ds) (originalRead ds c)

def IntCase := ∀ ds out, valid (outputShape (dims ds)) out →
  ∀ (x : List Nat → Int),
    ((operandReads ds out).map x).foldl (·+·) 0 = 0 + x (newOut ds out) * (count ds : Int)

/-- Nonnegative integer-valued binary32 RNE fragment; both side evaluations
stay far below binary32 exponent overflow. The additive identity is +0. -/
def FloatCase := ∀ ds out, valid (outputShape (dims ds)) out →
  1 ≤ count ds → count ds ≤ 256 →
  ∀ (x : List Nat → Nat), (∀ c, x c ≤ 2^24) →
    ((operandReads ds out).map (fun c => RadixIota.r32 (x c))).foldl
      (fun acc v => RadixIota.r32 (acc+v)) 0 =
      RadixIota.r32 (0 + RadixIota.r32 (RadixIota.r32 (x (newOut ds out)) *
        RadixIota.r32 (count ds)))
end RevisedBenchmark.ReduceMultiplicity
