# Independent review of HandleCompare

Accepted the four PRED forwarding model equations and the conditional Select/NE value theorem. Freeze 445145c, proof 6e149c0. All five frozen hashes matched. The specification and proof were unchanged from those commits. The iff quantifies over **all** predicate masks for a fixed value triple. Its forward direction tests the constant true and false masks at each coordinate. A single fixed GE mask alone does not force both arm conditions at every coordinate. The converse uses the arm selected at that coordinate. `integerGE` instantiates any two integer-valued tensors with literal mathematical 1/0 arms and 0 RHS.

At retained XLA e58e523b11f1fde802a493a776d158007486e1bf, algebraic_simplifier.cc lines 99–122 unwrap seven operand-zero operations and inspect the underlying literal. Lines 5961–5984 handle both operand orders of NE/false and EQ/true before the causal matcher at 6005–6017. For a PRED Select with recognized false RHS the earlier NE branch forwards the Select. The final source matcher requires a GE-producing compare, Select with recognized one/zero arms, recognized zero RHS and compatible output/predicate shapes. The model's arbitrary-mask theorem supplies the conditional mathematical fact without a branch-reachability or floating comparison claim. Literal.cc lines 2332–2350 and 2374–2402 perform typed conversion and literal checks. Concrete C++ integer recognition, typed layout/decoding, wrapper construction and graph execution remain outside the Lean result.

Read the complete custom closure in Tensor.lean, ConstantGuard.lean and ConstantGuardLemmas.lean. The guard computes finite storage uniformity independently of the value lookup; each wrapper supplies a total bounded address map. Unrecognized operations can denote constant tensors and still fail recognition. The proof uses the established one-way guard soundness theorem. Fresh Lean 4.35.0 eb6cafb7 in an empty temporary output directory returned 0 without warnings. Axiom checks for predGuards, causalBoundary, causalPred and integerGE each yielded only propext and Quot.sound. Shipped Std artifacts were reused. No native build or execution. The independent review controls below compiled as a separate temporary module, including a zero-extent vacuous case and a rank-one two-point GE switching truth value. Missing yes-arm disequality and missing no-arm equality each change the result at a different admitted point.


```lean
import CompareProof
open TensorRewrite.Pilot
open RevisedBenchmark.CompareGuards
private def sh : Shape 1 := fun _ => 2
private def ix (v : Fin 2) : Index sh := fun _ => v
private def lit (b : Bool) : ConstantGuard.View 1 sh :=
  .literal ⟨[b,b], fun i => i 0⟩
private def mask : Tensor sh Bool := fun i => decide ((i 0).val = 0)
private def xv : Tensor sh Int := fun i => if mask i then 3 else -1
private def zero : Tensor sh Int := Tensor.constant 0
example : PredGuards := predGuards
example : CausalBoundary := causalBoundary
example : CausalPred := causalPred
example : (lit false).isAll false = true ∧ (lit true).isAll true = true := by decide
example : (ConstantGuard.View.reindex .copy (lit true) id).isAll true = true := by decide
example : (ConstantGuard.View.unrecognized (shape := sh) (Tensor.constant false)).isAll false = false := by decide
example : (causal mask (lit true).eval (lit false).eval (lit false).eval (ix 0),
  causal mask (lit true).eval (lit false).eval (lit false).eval (ix 1)) = (true,false) := by decide
example : (causal (fun i => decide (xv i ≥ zero i)) (Tensor.constant 1) zero zero (ix 0),
  causal (fun i => decide (xv i ≥ zero i)) (Tensor.constant 1) zero zero (ix 1)) = (true,false) := by decide
example : causal mask zero zero zero (ix 0) ≠ mask (ix 0) := by decide
example : causal mask (Tensor.constant 1) (Tensor.constant 1) zero (ix 1) ≠ mask (ix 1) := by decide
private def emptyShape : Shape 1 := fun _ => 0
example (y n r : Tensor emptyShape Int) (p : Tensor emptyShape Bool) : causal p y n r = p :=
  (causalBoundary _ Int y n r).mpr (fun i => Fin.elim0 (i 0)) p
private def mixed : ConstantGuard.View 1 sh := .literal ⟨[true,false],fun i => i 0⟩
example : mixed.isAll false = false ∧ mixed.isAll true = false := by decide
example : mixed.eval (ix 0) ≠ mixed.eval (ix 1) := by decide
```

Shared review window 2026-11-17 23:14:44–23:16:51 UTC (127 s from first timestamp through reporting; excludes initial skill lookup). Human-style review time was interleaved and cannot be apportioned. Wall time includes compiler time. Common Tensor and ConstantGuard compiler time 0.776 s; count once across packets. Exclusive reasoning time, tokens and cost unknown. Compare-only compilation took 1.006 s for ConstantGuardLemmas, CompareSpec and CompareProof. Independent controls took 0.496 s initially and 0.510 s after adding mixed literal checks.
