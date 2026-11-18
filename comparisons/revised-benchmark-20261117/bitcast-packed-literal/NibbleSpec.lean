module
public import Std
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.BitcastPacked

abbrev Byte := BitVec 8
abbrev Nibble := BitVec 4

structure LayoutShape where
  width : Nat
  dims : List Nat
  minor : Option Nat
  explicitBits : Nat

def packedShape : LayoutShape := ⟨4,[2],some 0,4⟩
def scalarShape : LayoutShape := ⟨8,[],none,0⟩
def bytesFor (bits : Nat) := (bits+7)/8
def hloBytes (s : LayoutShape) := if s.explicitBits = 0 then s.dims.prod * bytesFor s.width
  else bytesFor (s.dims.prod * s.explicitBits)
def literalBytes (s : LayoutShape) := s.dims.prod * bytesFor s.width
def contiguous (s : LayoutShape) := s.dims ≠ [] ∧ s.minor = some (s.dims.length-1) ∧
  (if s.explicitBits = 0 then s.width % 8 = 0 else s.explicitBits = s.width)

def rawCopy (count : Nat) (memory : List Byte) : Option (List Byte) :=
  if count ≤ memory.length then some (memory.take count) else none

-- Both lane orders are represented; the equal-nibble witness needs neither convention.
def pack (lowFirst : Bool) (a b : Nibble) : Byte :=
  let (lo,hi) := if lowFirst then (a,b) else (b,a)
  BitVec.ofNat 8 (lo.toNat+16*hi.toNat)
def unpack (lowFirst : Bool) (b : Byte) : List Byte :=
  let lo := BitVec.ofNat 8 (b.toNat % 16)
  let hi := BitVec.ofNat 8 (b.toNat / 16)
  if lowFirst then [lo,hi] else [hi,lo]

def oldJoin (loFirst : Bool) (x y : Nibble) := some [pack loFirst x y]
def newJoin (x y : Nibble) := rawCopy (literalBytes scalarShape) [x.zeroExtend 8,y.zeroExtend 8]
def oldSplit (loFirst : Bool) (b : Byte) := some (unpack loFirst b)
def newSplit (b : Byte) := rawCopy (literalBytes packedShape) [b]

def Goal := contiguous packedShape ∧ packedShape.dims = scalarShape.dims ++ [scalarShape.width/packedShape.width] ∧
  hloBytes scalarShape = hloBytes packedShape ∧
  ∀ lowFirst : Bool, (¬ ∀ x y, oldJoin lowFirst x y = newJoin x y) ∧
    (∀ b, oldSplit lowFirst b ≠ newSplit b)
end RevisedBenchmark.BitcastPacked
