module
public import Std
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.WindowEarly

/-- Fields ending in M1 encode positive source window parameters minus one. -/
structure Axis where
  base : Nat
  widthM1 : Nat
  strideM1 : Nat := 0
  baseDilM1 : Nat := 0
  winDilM1 : Nat := 0
  low : Int := 0
  high : Int := 0
deriving Repr
def dilated (n d : Nat) := if n=0 then 0 else (n-1)*(d+1)+1
def extent (a : Axis) : Nat :=
  let span := (dilated a.base a.baseDilM1 : Int) + a.low + a.high
  let width := dilated (a.widthM1+1) a.winDilM1
  if span < width then 0 else (span-width).toNat/(a.strideM1+1)+1
inductive Coord : List Nat → Type where
  | nil : Coord []
  | cons {n ns} : Fin n → Coord ns → Coord (n :: ns)

def basePos (a : Axis) (out : Fin (extent a)) (tap : Fin (a.widthM1+1)) : Option (Fin a.base) :=
  let ix := ((out.val * (a.strideM1+1) + tap.val * (a.winDilM1+1) : Nat) : Int) - a.low
  let d := a.baseDilM1+1
  if 0 ≤ ix ∧ ix.toNat % d = 0 then
    if h : ix.toNat/d < a.base then some ⟨ix.toNat/d,h⟩ else none
  else none

def reads : (axes : List Axis) → Coord (axes.map extent) → List (Coord (axes.map Axis.base))
  | [], .nil => [.nil]
  | a::as, .cons y ys =>
    ((List.finRange (a.widthM1+1)).filterMap (basePos a y)).flatMap fun i =>
      (reads as ys).map (.cons i)

def window {α : Type} (axes : List Axis) (op : α → α → α) (init : α)
    (x : Coord (axes.map Axis.base) → α) (o : Coord (axes.map extent)) :=
  (reads axes o).foldl (fun acc p => op acc (x p)) init

def EmptyGoal := ∀ (α : Type) (axes : List Axis),
  0 ∈ axes.map Axis.base ∨ 0 ∈ axes.map extent →
  ∀ (op : α → α → α) (init : α) (x : Coord (axes.map Axis.base) → α),
  window axes op init x = fun _ => init

def ScalarGoal := ∀ (α : Type) (op : α → α → α) (init : α), (∀ v, op init v = v) →
   ∀ (x : Coord [] → α), window [] op init x = x

/-- Unary tuple at the computation root; the scalar clone evaluates its sole child. -/
structure One (α : Type) where value : α deriving Repr, DecidableEq

def SingletonGoal := ∀ (α : Type) (axes : List Axis) (op : One α → One α → One α)
    (init : α) (x : Coord (axes.map Axis.base) → α),
    window axes op ⟨init⟩ (fun i => ⟨x i⟩) =
    fun o => ⟨window axes (fun a b => (op ⟨a⟩ ⟨b⟩).value) init x o⟩
end RevisedBenchmark.WindowEarly
