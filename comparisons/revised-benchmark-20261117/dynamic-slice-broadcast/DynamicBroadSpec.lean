import TensorRewrite.Pilot.Tensor
import GatherHoistSpec
set_option autoImplicit false
namespace RevisedBenchmark.DynamicBroad
open TensorRewrite.Pilot

structure Plan (m n : Nat) where
  input : Shape m
  expanded : Shape n
  widths : Shape n
  axes : Fin m → Fin n
  matchExtent : ∀ a, input a = expanded (axes a)
  fits : ∀ a, widths a ≤ expanded a
def slice {n : Nat} {s t : Shape n} {α : Type} (h : ∀ a, t a ≤ s a)
    (starts : Fin n → Int) (x : Tensor s α) : Tensor t α :=
  fun q => x (fun a => GatherHoist.atStart (h a) (starts a) (q a))
def broad {m n : Nat} {s : Shape m} {t : Shape n} {α : Type} (axes : Fin m → Fin n)
    (h : ∀ a, s a = t (axes a)) (x : Tensor s α) : Tensor t α :=
  fun q => x (fun a => Fin.cast (h a).symm (q (axes a)))
def widths {m n : Nat} (p : Plan m n) : Shape m := fun a => p.widths (p.axes a)
def Case := (∀ {m n} (p : Plan m n),
  ∃ h : ∀ a, widths p a ≤ p.input a,
  ∀ {α : Type} (x : Tensor p.input α) (starts : Fin n → Int),
  slice p.fits starts (broad p.axes p.matchExtent x) =
    broad p.axes (fun _ => rfl) (slice h (fun a => starts (p.axes a)) x)) ∧
  (∀ {n} (p : Plan 0 n) {α : Type} (x : Tensor p.input α) (starts : Fin n → Int),
    slice p.fits starts (broad p.axes p.matchExtent x) =
      (fun _ => x (fun a => a.elim0)))
end RevisedBenchmark.DynamicBroad
