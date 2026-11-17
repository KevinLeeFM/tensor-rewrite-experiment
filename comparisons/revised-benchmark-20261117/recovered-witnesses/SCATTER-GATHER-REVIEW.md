# Independent Scatter and Gather witness review

The three retained records have nonvacuous, kernel-checked model counterexamples. Both Scatter orientations disprove preservation for the admitted rank-one single-update S32 examples. The signed Gather counterexample disproves preservation for an admitted rank-one singleton-slice profile with threshold 129. These are three recovered model verdicts, with two distinct Scatter source arms sharing one arithmetic witness family. They add zero newly discovered counterexamples or accepted source proofs. The archived pinned XLA runs separately reproduce the corresponding host-evaluator changes.

## Identities and boundaries

I reviewed the frozen evidence at `d1b6ab01f65010c5180146ddd3a30434ddeccba1`. All 21 inputs in [SHA256SUMS](SHA256SUMS) matched, and the four compiled closure files plus the control fixture matched that Git revision. [The case map](../../../census/site-case-map.json) identifies the exact mutation/replacement sites; [pilot-values](../../../reports/pilot-values.json) and [the native receipt](../../../reports/reducer-index-replay-v1/result.json) agree on XLA revision `e58e523b11f1fde802a493a776d158007486e1bf`. The local simplifier source matches SHA-256 `1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f`. The XLA tree was inspected as a source snapshot, so I verified the body hash directly and took the XLA commit identity from the matching receipts. The trusted Lean compiler was 4.35.0 x86-64 Linux commit `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.

| Retained ID | Model verdict | Fresh evidence | Archived native rows / actual rewrites / value changes |
| --- | --- | --- | --- |
| `HandleAdd/scatter-single-rhs` | Counterexample to opcode-only preservation for the single-update rank-one word model | Direct imported certificate and `p00`/`p11` witness vectors | 24 / 8 / 4 |
| `HandleAdd/scatter-single-lhs` | Counterexample in the same word model with both Adds in their literal left-Scatter order | Kernel-checked review adapter derives the exact left-Scatter negated equality from the existing right-Scatter certificate | 24 / 8 / 4 |
| `HandleGather/small-select-chain` | Counterexample to signed-clamp preservation for the signed-eight-bit one-coordinate model | Direct coordinate certificates at extent 129 and signed indices 0, −1, and 127; the fixture labels data by its coordinate | 27 / 14 / 6 |

### Both single-Scatter branches

At [simplifier lines 1095–1117 and 1248–1259](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L1095), the relevant options must be layout-insensitive. The selected operand matches a three-operand Scatter with one use and an Add of two Parameter instructions at the reducer root. The other operand fails this matcher, so the preceding two-Scatter branch is skipped. Neither Parameter pattern constrains its role number or requires distinct operands. The separate Add operand is a runtime parameter in the fixture, and the archived graphs show it in the intended orientation prior to either rewrite. The rewrite changes only the Scatter base before replacing the outer Add, reusing its index, update and reducer. The proof model assumes one valid in-bounds update and mathematical word addition. Layout, metadata, other dtypes, arbitrary scatter indexing/windows or multiple updates, and the concat/nested two-Scatter paths remain outside this review.

For separate vector `a = [1,1]`, base `b = [3,3]`, valid target 0, update 5 and S32 arithmetic, both orientations produce `[7,4] → [8,4]` when the reducer uses `old + old`, and `[11,4] → [10,4]` for `update + update`. The original updated entries are `1 + (3 + 3)` and `1 + (5 + 5)`. The corresponding replacements are `(1 + 3) + (1 + 3)` and `5 + 5`. Position 1 remains 4 in all cases. Both mixed roles give `[9,4] → [9,4]`, corroborating the more general existing `distinct_parameters_preserve` theorem. These controls show that the witness identifies repeated parameter roles and that the model has a nonempty index domain.

For RHS Scatter, `before` is `a + scatter(b)` and `after` is `scatter(a + b)`, matching the literal source order. LHS Scatter is `scatter(b) + a` and becomes `scatter(b + a)`. The inherited theorem directly states only the RHS ordering. The review-only adapter below swaps the outer Add pointwise and independently swaps the Add of the base tensors pointwise, via `BitVec.add_comm`; it preserves the exact reducer roles and derives the negated LHS equality with the same fixed witness. The adapter is in this report and was compiled from a temporary audit file. It makes no edit to any repository Lean module and depends on no concurrent proof work.

### Small signed Gather

At [simplifier lines 4634–4686](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc#L4634), empty and effective-scalar operands take earlier arms. The target branch requires rank one, extent no larger than the configured threshold, an implicit scalar index-vector dimension at the index shape rank, and one collapsed slice dimension. The verified fixture uses `start_index_map={0}`, `collapsed_slice_dims={0}`, `slice_sizes={1}`, `offset_dims={}`, a one-entry runtime index tensor with `index_vector_dim=1`, and data `data[i]=i`. The model exposes one observed coordinate of that Gather. It computes the original clamp `min (extent - 1) (max 0 signedIndex)`. The replacement initializes element 0 and walks positions 0 through extent−1 in order, using signed GE against the generated literal at each step. [MakeScalarLike](../../../sources/xla/xla/service/hlo_creation_utils.h#L330) converts the integral literal to the index element type. The fixture separately observes conversion `128 → −128`, and the archived post-rewrite graph shows the actual `s8[] constant(-128)` and a Select root.

At threshold 129 and extent 129, the final comparison against −128 overwrites the intended location. Witnesses `(0,−1,127)` produce original coordinates `(0,0,127)` and replacement coordinates `(128,128,128)`. This is a kernel-checked coordinate difference and distinguishes values with the explicit label tensor. Extent 128 with S8 index 127 returns 127 on both sides with the rewrite active. At extent 129, thresholds 128 and the [default 4](../../../sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier_options.proto#L72) suppress the arm and preserve 0. S32 indices 0, 200, and −1 at extent/threshold 129 return 0, 128, and 0 on both sides with the rewrite active. The separate theorem `selectedIndex_eq_original` proves the stronger control given exact signed representation of all generated positions. The negative theorem itself fixes numeric extent 129 and does not encode source option gates; the reviewed fixture satisfies them. This says nothing about all Gather dimensions, index types, platform conversions, or branches.

## Archive versus fresh work

I verified all six file hashes in the native receipt and compared all 75 unique profile/mode rows against both `build.log` and `test.log`, including before/after values, rewrite status, and verification status. The XML reports two passed cases, zero failures/errors, and 0.093 s total fixture time, with 0.027 s assigned to all Scatter fixture profiles and 0.065 s to Gather. The archived Bazel invocation took 16.995377202983946 s. Its 75 rows comprise 25 each for control, direct handler, and full pass. The recorded 30 applied rewrites and 14 value changes split into two changed Scatter roles across each orientation and both active modes (8 differences), and three Gather indices across both active modes (6). The 16 additional active rows preserved values. All 75 were marked verified. The layout-sensitive Scatter settings suppress the target arm; the narrow Gather threshold controls show nonapplication separately from rewrites that preserve results. The tests parsed verified originals, used HLO verification after transformations, and evaluated typed host values with the fast path disabled. This review performed no native execution or build. The recorded host behavior has no independent backend execution or formal C++–Lean correspondence.

The complete local Lean import chain is `ReducerIndexCertificates → ReducerIndexLemmas → ReducerIndex → Tensor → Std`. All four custom files were read and freshly compiled in an empty temporary output tree from the frozen source. `Tensor` contains generic shape, bounded index and pointwise value definitions. The other three contain the literal word/index definitions, arithmetic controls, and explicit existing certificates shown here. Lean/Std are supplied by the pinned distribution. No Mathlib, Lake cache or other project module is imported. There were no compiler warnings or errors. The available permit list is `propext`, `Quot.sound`, and `Classical.choice`; the actual transitive audits used subsets. The direct Scatter refutations used only `propext`; the commuted adapter and refutation, distinct-role Scatter support, and represented-literal Gather support used `propext, Quot.sound`. The five Gather certificates used no axioms. There is no `sorryAx`, `native_decide`, or admitted project axiom in these targets.

## Reproduction and cost

Run from the benchmark repository root. Save the code in the section below as `"$out/Audit.lean"` before the final command. The fixture is unchanged except for replacing its umbrella import with the exact certificate import. The original fixture SHA-256 is `6f6d4b8fd6bdf8e4ce69dc7e1f102d224db18a8b9512cf55b116955d6f8d0c89`; the narrowed fixture is `ec11b5751d106463438d4ed07591e01b2a420c2bdd7bb03ffab3d858988c9b76`. The exact audit below has SHA-256 `3d8075818704105bc2ed84d0358f461ba58dc24ec2a810a2fb483bb4c0619223`.

```bash
set -euo pipefail
out=$(mktemp -d)
mkdir -p "$out/TensorRewrite/Pilot"
export LEAN_PATH="$out"
lean=/workspace/toolchains/lean-4.35.0-linux/bin/lean
for module in Tensor ReducerIndex ReducerIndexLemmas ReducerIndexCertificates; do
  time timeout 30s "$lean" -o "$out/TensorRewrite/Pilot/$module.olean" \
    "TensorRewrite/Pilot/$module.lean"
done
sed '1s/^import TensorRewrite$/import TensorRewrite.Pilot.ReducerIndexCertificates/' \
  tests/fixtures/ReducerIndexControls.lean > "$out/Controls.lean"
time timeout 30s "$lean" "$out/Controls.lean"
time timeout 30s "$lean" "$out/Audit.lean"
```

Measured per-command compiler times were 0.306 s (Tensor), 0.332 s (ReducerIndex), 0.384 s (Lemmas), 0.382 s (Certificates), 0.370 s (13 fixture probes) and 0.446 s (types, adapter and axiom audit), for 2.220 s total shared elapsed compiler time. This cost is shared across all three records. The initial timing invocation failed because `/usr/bin/time` was absent, before starting Lean. Bash's built-in timing corrected it. No compiler or proof attempt failed. Native effort and original counterexample discovery time cannot be derived from this review. Active reasoning time and tokens were not instrumented.

### Exact review-only audit

```lean
import TensorRewrite.Pilot.ReducerIndexCertificates

set_option autoImplicit false
open TensorRewrite.Pilot.ReducerIndex

#check BitVec.add_comm
#check ScatterRoles.not_universally_preserving
#check GatherLiterals.not_universally_preserving

theorem reflectedScatter {size width : Nat} (p q : ScatterRoles.Parameter)
    (a b : Fin size → BitVec width) (t : Fin size) (u : BitVec width) :
    (fun i => ScatterRoles.scatter p q b t u i + a i) =
        ScatterRoles.before p q a b t u ∧
      ScatterRoles.scatter p q (fun i => b i + a i) t u =
        ScatterRoles.after p q a b t u := by
  constructor
  · funext i
    exact BitVec.add_comm _ _
  · have bases : (fun i => b i + a i) = (fun i => a i + b i) := by
      funext i
      exact BitVec.add_comm _ _
    rw [bases]
    rfl

theorem leftScatterCounterexample :
    ¬ (∀ p q,
      (fun i => ScatterRoles.scatter p q ScatterRoles.base 0 5 i + ScatterRoles.lhs i) =
        ScatterRoles.scatter p q (fun i => ScatterRoles.base i + ScatterRoles.lhs i) 0 5) := by
  intro preserving
  apply ScatterRoles.not_universally_preserving
  intro p q
  obtain ⟨before, after⟩ := reflectedScatter p q ScatterRoles.lhs ScatterRoles.base 0 5
  exact before.symm.trans ((preserving p q).trans after)

#print axioms ScatterRoles.current_update_preserves
#print axioms ScatterRoles.update_current_preserves
#print axioms ScatterRoles.distinct_parameters_preserve
#print axioms ScatterRoles.repeated_current_changes
#print axioms ScatterRoles.repeated_update_changes
#print axioms ScatterRoles.not_universally_preserving
#print axioms reflectedScatter
#print axioms leftScatterCounterexample
#print axioms GatherLiterals.selectedIndex_eq_original
#print axioms GatherLiterals.literal_128_narrows
#print axioms GatherLiterals.zero_index_changes
#print axioms GatherLiterals.negative_index_changes
#print axioms GatherLiterals.maximum_index_changes
#print axioms GatherLiterals.not_universally_preserving
```

Observed independent review window: 2026-11-17 22:28:47 UTC through 2026-11-17 22:31:38 UTC. This includes setup, source/evidence inspection, targeted replay and report writing. Active reasoning time was not measured.

## Separate follow-on review of the exact modular Scatter criterion

**Accepted for both literal one-update word-model orientations.** The exact theorem `RevisedBenchmark.ScatterExact.correct : RevisedBenchmark.ScatterExact.Goal` is new at `fcec64d9de73607a9cbe0956bd33bd7a0796059e`, under the distinct statement freeze `ec092eae28438a12493e77189bdf7598a9a29fd1`. This is a new necessary-and-sufficient characterization built on the archived model and its distinct-role theorem. It does not replace the nonvacuous guard-only refutations above or count as an additional retained source-record identity. I was not its proof author. My earlier recovery review independently checked the expected commutativity reduction; the new proof was obtained from Git and checked directly.

All six [freeze hashes](../scatter-exact/SHA256SUMS) matched. The specification, inherited model/lemma closure, Lean pin, source file and contract were unchanged between the freeze and checked proof. The working files used for the replay also matched the proof commit. The proof file SHA-256 is `90f0ce0091506d01f84607d18d099a85b0dcc1ea1840ec255e9d1b08d0ac56bb`; controls hash `d065bced732b7de68d8244fe332dcf5ed52801697ff76e8684deb97096c298a3`. The fully elaborated goal printed as

```lean
∀ {n w : Nat} (scatterLeft : Bool) (a b : Parameter) (extra base : Fin n → BitVec w)
    (t : Fin n) (u : BitVec w),
  original scatterLeft a b extra base t u =
    replacement scatterLeft a b extra base t u ↔ a ≠ b ∨ extra t = 0
```

The theorem compares whole vectors, with arbitrary extent and word width, arbitrary distinct or repeated reducer roles, an actual target `Fin n`, unconstrained separate and base vectors and an arbitrary update. Extent zero has no admitted target and width zero has a unique word. Signed and unsigned interpretations share the underlying stored-bit equality. In [ScatterSpec](../scatter-exact/ScatterSpec.lean), the orientation bit directly controls both the outer Add and the replacement base Add. It changes neither callback role nor callback operand order. The proof reduces LHS to RHS using two independent applications of pointwise word commutativity, one for each changed operand order.

Write `x = extra[t]`, `y = base[t]`, and `u` for the update. For repeated current, the compared entries are `x+(y+y)` and `(x+y)+(x+y)`. Associativity and commutativity write the latter as `x + (x+(y+y))`. For repeated update the compared entries are `x+(u+u)` and `u+u`. Both equations imply `x=0` by cancellation of a common addend in modular word addition. There is no cancellation of a factor 2 or no-overflow premise. Sufficiency with distinct roles reuses the existing theorem that covers both `current,update` and `update,current`. Otherwise `x=0` makes the target equal by definition, and the untargeted entries equal independently of `x` or any other entry of the separate vector. This latter branch genuinely tests pointwise equality away from the update.

The new [controls](../scatter-exact/ScatterControls.lean) compiled for both orientations and both repeated roles with target extra 0 and off-target extra 17. The unequal repeated-update LHS values were 27 and 10, and the unequal repeated-current RHS values were 29 and 46. The zero-width control allows arbitrary roles and both orientations. I also checked an independent mixed-role overflow example for both orientations: at width 8, `extra=17`, `base=254`, `update=4`, both results are 19. The inherited concrete witnesses and archived native observations remain applicable only to their stated source profiles.

For fresh replay, use the earlier setup with an empty output directory. Compile only `Tensor`, `ReducerIndex`, and `ReducerIndexLemmas` to that tree. From `comparisons/revised-benchmark-20261117/scatter-exact`, compile `ScatterSpec.lean`, `ScatterProof.lean` and `ScatterControls.lean` in that order, with `-o "$out/<module>.olean"`. The temporary independent audit below elaborated the explicit formula independently of the author proof's `Goal` alias. It returned only `[propext, Quot.sound]` for the exact theorem, with no errors or warnings. No other custom imports were used, and no native test was run. This result covers the stated abstract one-update model. Multi-update or overlapping Scatter, layout and effect conditions, floating data and any formal source correspondence remain outside scope.

Measured elapsed compiler times were 0.348 s for Tensor, 0.321 s for the model, 0.350 s for inherited lemmas, 0.295 s for the specification, 0.316 s for the theorem, 0.274 s for controls, and 0.307 s for the independent explicit-target and wraparound audit. Total 2.211 s, separate from the recovered-witness replay above. The fresh follow-on had no failed checks. The independent audit source hash was `00eb2d38dc6033fca964cc953015e36bb3022b356e285cfd75dd266331d45d1b`.

```lean
import ScatterProof
open RevisedBenchmark.ScatterExact
open TensorRewrite.Pilot.ReducerIndex.ScatterRoles
set_option autoImplicit false

#print Goal
#print axioms correct

example : ∀ {n w : Nat} (left : Bool) (p q : Parameter)
    (a b : Fin n → BitVec w) (t : Fin n) (u : BitVec w),
    original left p q a b t u = replacement left p q a b t u ↔
      p ≠ q ∨ a t = 0 := correct

example (left : Bool) :
    original left .current .update (fun _ : Fin 1 => 17#8)
      (fun _ => 254#8) 0 4 0 = 19#8 ∧
    replacement left .current .update (fun _ : Fin 1 => 17#8)
      (fun _ => 254#8) 0 4 0 = 19#8 := by
  cases left <;> decide
```

Separate follow-on review window: 2026-11-17 22:31:44 UTC through 2026-11-17 22:32:43 UTC, including setup, source inspection, compiler checks, and report writing. Reasoning/token cost was not instrumented.
