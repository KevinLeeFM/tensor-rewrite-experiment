module
public import TensorRewrite.Pilot.Reshape
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.EffectiveGather
open TensorRewrite.Pilot

/-- Each operand axis has a decoded start-vector component, explicit batch coordinate,
or the implicit zero start. The dimension-number maps have already been decoded. -/
inductive Start (resultRank vectorSize : Nat)
  | component (k : Fin vectorSize)
  | batch (axis : Fin resultRank)
  | zero

/-- Projected Gather coordinates. Every well-formed output supplies a bounded offset
in its window; collapsed and batching axes supply zero with effective width one.
The component lookup may depend on the output's batch position. -/
structure Window {r t : Nat} (src : Shape r) (dst : Shape t) where
  vectorSize : Nat
  start : Fin r → Start t vectorSize
  readComponent : Index dst → Fin vectorSize → Int
  width : Shape r
  fits : ∀ a, width a ≤ src a
  offset : Index dst → Index width

/-- Clamp starts to fit the window, then add the in-window offset. -/
def position {r t : Nat} {src : Shape r} {dst : Shape t}
    (g : Window src dst) (o : Index dst) (a : Fin r) : Fin (src a) :=
  let raw : Int := match g.start a with
    | .component k => g.readComponent o k
    | .batch b => Int.ofNat (o b).val
    | .zero => 0
  let start := min raw.toNat (src a - g.width a)
  ⟨start + (g.offset o a).val, by
    have h := (g.offset o a).isLt
    have f := g.fits a
    have m : start ≤ src a - g.width a := Nat.min_le_right ..
    omega⟩

/-- Read the operand at the computed multidimensional index. -/
def gather {r t : Nat} {src : Shape r} {dst : Shape t} {α : Type}
    (g : Window src dst) (x : Tensor src α) : Tensor dst α :=
  fun o => x (position g o)

abbrev scalar : Shape 0 := fun a => a.elim0
abbrev origin : Index scalar := fun a => a.elim0

/-- A shape with only unit extents has the scalar's element count. -/
theorem countOne {r : Nat} (s : Shape r) (unit : ∀ a, s a = 1) :
    LinearIndex.elementCount s = LinearIndex.elementCount scalar := by
  change LinearIndex.elementCount s = 1
  induction r with
  | zero => rfl
  | succ k ih =>
    change s 0 * LinearIndex.elementCount (fun a : Fin k => s a.succ) = 1
    rw [unit 0, Nat.one_mul, ih _ (fun a => unit a.succ)]

/-- Rank zero forwards the operand scalar; positive rank reshapes it in logical
row-major order first. Both broadcasts have exactly the declared Gather shape. -/
def Case : Prop :=
  (∀ (t : Nat) (dst : Shape t) (α : Type) (x : Tensor scalar α) (g : Window scalar dst),
    gather g x = Tensor.constant (x origin)) ∧
  (∀ (k t : Nat) (s : Shape (k+1)) (unit : ∀ a, s a = 1) (dst : Shape t) (α : Type)
    (x : Tensor s α) (g : Window s dst),
    gather g x = Tensor.constant (Reshape.reshapeTensor x scalar (countOne s unit) origin))

end RevisedBenchmark.EffectiveGather
