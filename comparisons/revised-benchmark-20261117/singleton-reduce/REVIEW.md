# Independent review of singleton-tuple Reduce

**Accepted for the complete declared logical-value partition.** The proof is at Git revision `433254095a4b113c1c6ab4e2cc21883b341a5d97`; its statement and structural reuse were frozen at `4840655`. This contributes one verified partition to `HandleReduce/singleton-tuple`. The broader retained source record remains open.

## Exact statement and source boundary

`RevisedBenchmark.SingletonReduce.unpack : RevisedBenchmark.SingletonReduce.Goal` quantifies over every Lean `α : Type`, reduction `Plan`, total pure reducer body `α → α → Fin 1 → α`, initializer and input tensor. The entire result is a function from the singleton tuple slot to an output tensor, on the same statically derived output shape on both sides. For every output coordinate, the source model folds the unchanged ordered fiber in singleton-tuple state, projecting the scalar arguments at slot zero before applying the body. The replacement folds the same original inputs and initializer using the body's slot-zero expression and wraps the result in a singleton tuple. The shape is shared by construction and every index is bounded. Plans encode arbitrary finite rank, arbitrary kept and reduced axis selections, and all natural extents including zero. An empty fiber returns the actual initializer; an empty output has no valid coordinate. No law of associativity, commutativity, initializer identity, or reducer compatibility is a hypothesis. Compatibility is proved by `Subsingleton.elim` on `Fin 1`.

At pinned XLA `e58e523b11f1fde802a493a776d158007486e1bf`, the source branch first observes tuple output, one tuple component, one input and a literal Tuple reducer root. It discards that root in the clone and selects the original operand zero as the new root. It builds a scalar Reduce with the representative result shape, sole original input/init and the original dimensions, and wraps that reduction in a Tuple. The clone implementation looks up a null replacement, skips removed instructions, clones remaining instructions with their cloned operands, and resolves the supplied explicit root through the clone context. Pure expression interpretation justifies the selected component relationship. Earlier zero-element input or output dispatch preempts this branch; the empty controls are checked model boundaries. Same-count reshape comes later and is a different operation with a different initializer assumption. The following layout-sensitive early return also comes later. The packet observes logical shapes and values only. [Dispatch and replacement](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L9044) · [Zero-element predicate](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L8851) · [Clone implementation](../../../sources/xla/xla/hlo/ir/hlo_computation.cc#L2377) · [Clone root selection](../../../sources/xla/xla/hlo/ir/hlo_computation.cc#L2496)

The observation assumes a common ordered, homogeneous, pure and total scalar interpretation. The source verifier accepts precision differences in some initializer and input parameter compatibility checks. The common-type Lean model supplies no model for those conversions, arbitrary differences in backend reduction order or grouping, IEEE-specific observations, physical layout, dynamic metadata, graph mutations or failure behavior. The public Reduce semantics documents identity and rough associativity and publicly describes the ordinary one-input return as a scalar; the specific singleton-tuple HLO branch and verifier are the relevant evidence for the modeled tuple shape. The nonidentity example is an admissible Lean model control. Source execution/reachability and C++–Lean correspondence were outside this review. [Reducer shape verifier](../../../sources/xla/xla/service/shape_inference.cc#L89) · [Reduce semantics](../../../sources/xla/docs/operation_semantics.md#L3831) · [Source action registry](../../../census/source-normalization-registry.json#L5588)

## Reuse and integrity

The historical full `ReductionFiberLemmas.lean` blob at `1714add5ca6f5f712b934d9a73b36a47448e1b30` is byte-identical to the one in the accepted source revision and agrees with the packet's frozen hash. Inclusive source ranges 73–84 and 170–179, including doc comments, match `StructuralReuse.lean` lines 8–19 and 21–30 byte-for-byte. Only surrounding imports, opens and namespace differ. The historical module brings in Mathlib for unrelated statements. Its copied fiber map transports each list position by induction on `Plan`; the copied fold lemma transports the actual initial value and each update by induction on the original list. Neither assumes a rewrite-specific equality. The existing `ReductionAlgebra.map_reduction` theorem already combines these two generic steps assuming homomorphism. This packet specializes them and derives singleton conjugacy; classify it as established-library reuse, rather than a new generic reduction transport result. The existing singleton `WindowTupleFamily` proof uses different window geometry/padding. Empty-broadcast and same-count proofs use different replacement expressions. No historical paper outcome or other retained row receives credit. [Historical declarations](../../../TensorRewrite/Theory/ReductionFiberLemmas.lean#L73) · [Generic combining theorem](../../../TensorRewrite/Theory/ReductionAlgebra.lean#L112) · [Window theorem](../../../TensorRewrite/Theory/WindowTupleFamilyProof.lean)

All eight SHA256SUMS entries passed, and the seven compiled input files matched the exact Git blobs. The implementation file for cloning also matched its pinned supplement hash `f3afcd7e3122e17e36462dd70b1cb947be16c725cc2235432829bbf33d6f5aef`. The proof file hash is `c36adc771da11ee396e2d4c926f0bc9e33a577bc1c3255888a5e889f8384a042`. The freeze-to-proof diff adds only `SingletonProof.lean`. The local elaboration closure is four existing Pilot modules (`FiniteProduct`, `Tensor`, `LinearIndex`, `Reduction`) and three packet modules (`SingletonSpec`, `StructuralReuse`, `SingletonProof`), with compiler-provided Std/Init as external foundation. The original Mathlib-backed historical module was checked as source provenance only. Kernel axiom output was `[propext, Quot.sound]` for `unpack` and `fiberValues_map`, and empty for `foldl_map_hom`. No unapproved axioms or admitted proof terms were found. This used exact declaration elaboration against source-matched semantic definitions and fresh kernel compilation of the local closure.

## Independent replay and controls

Lean 4.35.0, Linux x86-64, `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. The two-element fiber `[1,2]` with initializer `3` and nonassociative operation `2*a+b` returns `16` on both sides. Replacing that scalar operation with addition returns `6`, refuted against the original packed reduction by a kernel-checked inequality. Both sides return `13` on a unit reduced axis, and `3` on a zero reduced axis. A separate bounded-coordinate check confirms a kept zero extent admits no output coordinate. The packet's scalar control was also replayed.

The final replay used about three seconds wall, including fresh extraction/setup. Serial command times in module order were 0.413, 0.319, 0.382, 0.430, 0.295, 0.455, 0.305 and 0.380 seconds including the supplemental checker. Earlier control attempts had optional kept-zero harness errors (`IsEmpty` unavailable, then dependent numeral and `Fin.elim0` elaboration) and one command wrapper error (`/usr/bin/time` absent). These were review harness overhead. They were resolved with explicit coordinate extent/bound checks and Bash timing; the target and dependency files were unchanged. Summed command timings for the three failed control passes were about 3.18, 3.24 and 2.80 seconds respectively, including recompilation of the seven successful target modules. The missing command invoked no compiler. The observed review and report window was approximately four minutes from 22:03:37 UTC. Active reasoning and token costs were unmeasured. No discovery timing follows from this replay.

Run from the repository root. The calls use a fresh local temporary directory and the installed compiler, with no Lake build or dependency download.

```bash
sha256sum -c comparisons/revised-benchmark-20261117/singleton-reduce/SHA256SUMS
set -eu
r=433254095a4b113c1c6ab4e2cc21883b341a5d97
p=comparisons/revised-benchmark-20261117/singleton-reduce
lean=/workspace/toolchains/lean-4.35.0-linux/bin/lean
d=$(mktemp -d)
trap 'rm -rf "$d"' EXIT
mkdir -p "$d/TensorRewrite/Pilot"
for m in FiniteProduct Tensor LinearIndex Reduction; do
    git show "$r:TensorRewrite/Pilot/$m.lean" > "$d/TensorRewrite/Pilot/$m.lean"
done
for m in SingletonSpec StructuralReuse SingletonProof; do
    git show "$r:$p/$m.lean" > "$d/$m.lean"
done
cd "$d"
TIMEFORMAT="%3Rs"
export LEAN_PATH="$d"
for m in TensorRewrite/Pilot/{FiniteProduct,Tensor,LinearIndex,Reduction} SingletonSpec StructuralReuse SingletonProof; do
    printf "%s\n" "$m"
    time timeout 20 "$lean" -o "$m.olean" "$m.lean"
done
cat > ReviewControls.lean <<'LEAN'
import SingletonProof
open TensorRewrite.Pilot TensorRewrite.Pilot.Reduction RevisedBenchmark.SingletonReduce
set_option autoImplicit false
#print Goal
#check (unpack : Goal)

private def body (a b : Nat) (_ : Fin 1) := 2*a+b
private def lhs (p : Plan) (xs : Tensor p.inputShape Nat) (j : Index p.outputShape) :=
  reduceTensor p (fun a b => body (a 0) (b 0)) (fun _ : Fin 1 => 3) (fun i _ => xs i) j 0
private def rhs (p : Plan) (xs : Tensor p.inputShape Nat) (j : Index p.outputShape) :=
  reduceTensor p (fun a b => body a b 0) 3 xs j
private def scalar : Index Plan.scalar.outputShape := fun i => i.elim0
private def pair : Tensor (Plan.reduce 2 .scalar).inputShape Nat :=
  fun i => (i ⟨0, by decide⟩).val + 1
example : lhs (.reduce 2 .scalar) pair scalar = 16 := by decide
example : rhs (.reduce 2 .scalar) pair scalar = 16 := by decide
example : reduceTensor (.reduce 2 .scalar) Nat.add 3 pair scalar = 6 := by decide
example : lhs (.reduce 2 .scalar) pair scalar ≠
    reduceTensor (.reduce 2 .scalar) Nat.add 3 pair scalar := by decide
example : lhs (.reduce 0 .scalar) (fun _ => 7) scalar = 3 := by decide
example : rhs (.reduce 0 .scalar) (fun _ => 7) scalar = 3 := by decide
example : lhs (.reduce 1 .scalar) (fun _ => 7) scalar = 13 := by decide
example : rhs (.reduce 1 .scalar) (fun _ => 7) scalar = 13 := by decide
example (j : Index (Plan.keep 0 (.reduce 2 .scalar)).outputShape) : False := by
  let axis : Fin (Plan.keep 0 (.reduce 2 .scalar)).outputRank := ⟨0, by decide⟩
  have hshape : (Plan.keep 0 (.reduce 2 .scalar)).outputShape axis = 0 := by decide
  have hbound := (j axis).isLt
  omega
#print axioms RevisedBenchmark.SingletonReduce.Reuse.fiberValues_map
#print axioms RevisedBenchmark.SingletonReduce.Reuse.foldl_map_hom
#print axioms unpack
LEAN
echo ReviewControls
time timeout 20 "$lean" ReviewControls.lean
```
