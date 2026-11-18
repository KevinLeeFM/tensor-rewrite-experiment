import PadDotSpec
set_option autoImplicit false
namespace RevisedBenchmark.ConvFilter
open RevisedBenchmark.PadDot

structure Window where
  input : Nat
  kernel : Nat
  gap : Nat
  stride : Nat
  baseDilation : Nat
  oldDilation : Nat
  low : Int
  high : Int
  reverse : Bool
deriving Repr

def support (a : Window) : Axis := ⟨a.kernel,0,0,a.gap⟩
def newDil (a : Window) := if a.gap = 0 then a.oldDilation else a.gap+1
def ok (a : Window) := a.stride > 0 ∧ a.baseDilation > 0 ∧ a.oldDilation > 0 ∧
  (a.gap = 0 ∨ a.oldDilation = 1)
def span (n d : Nat) := if n = 0 then 0 else (n-1)*d+1
def output (a : Window) (n d : Nat) : Nat :=
  ((a.low + (span a.input a.baseDilation : Int) + a.high - (span n d : Int)) /
    (a.stride : Int) + 1).toNat
def oldShape (a : Window) := output a (extent (support a)) a.oldDilation
def newShape (a : Window) := output a a.kernel (newDil a)

def offset (rev : Bool) (n d j : Nat) := (if rev then n-1-j else j)*d
def oldOff (a : Window) := offset a.reverse (extent (support a)) a.oldDilation
def newOff (a : Window) := offset a.reverse a.kernel (newDil a)

/-- Recover the input position from a window displacement at one output. -/
def inputAt (a : Window) (q tap : Nat) : Option Nat :=
  let p : Int := ((q*a.stride + tap : Nat) : Int) - a.low
  if 0 ≤ p ∧ p.toNat % a.baseDilation = 0 ∧ p.toNat / a.baseDilation < a.input then
    some (p.toNat / a.baseDilation) else none

def sample (ws : List Window) (q taps : List Nat) (x : List Nat → Int) : Int :=
  match ((ws.zip (q.zip taps)).mapM fun (a,o,t) => inputAt a o t) with
  | some i => x i
  | none => 0

/-- At a fixed batch and output channel, enumerate every incoming feature in that group. -/
def oldConv (ws : List Window) (q : List Nat) (features : Nat)
    (x k : Nat → List Nat → Int) : Int :=
  total (List.range features) fun c =>
    original (ws.map support) false (k c) (fun j => sample ws q (List.zipWith oldOff ws j) (x c))

def newConv (ws : List Window) (q : List Nat) (features : Nat)
    (x k : Nat → List Nat → Int) : Int :=
  total (List.range features) fun c =>
    total (grid (ws.map Window.kernel)) fun j =>
      sample ws q (List.zipWith newOff ws j) (x c) * k c j

def Case : Prop := ∀ (ws : List Window), (∀ a ∈ ws, ok a) →
  ws.map oldShape = ws.map newShape ∧ ∀ q ∈ grid (ws.map oldShape),
    ∀ features x k, oldConv ws q features x k = newConv ws q features x k
end RevisedBenchmark.ConvFilter
