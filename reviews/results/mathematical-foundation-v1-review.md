# Independent mathematical foundation review v1

Outcome: **issues requiring correction**. Two evidence/accounting issues require correction. I found no false mathematical statement or blocking mathematical defect in the inspected 89-statement foundation. This is separate scrutiny, not a trusted oracle or a whole-workload approval. Benchmark-label correspondence is not certified.

## Findings

### MF-01 — P2, bookkeeping: 30 retained mathematical declarations omitted from the ledger

`tools/mathematical_ledger.py:77–95` registers selected lists from the pilot manifest, skipping explicitly retained mathematical evidence. The omitted names include the constant-recognition bridge, consistency and concrete-witness certificates, unsigned-index and nested-slice diagnostics, control-order/repair certificates, and four zero-MAC certificates.

Minimal example: `census/pilot-value-proofs.json:956` names `TensorRewrite.Pilot.BooleanDag.and_rhs_true_of_isAll`, whose theorem is at `TensorRewrite/Pilot/GuardedBooleanDag.lean:15`; it never enters `evidence()` or the generated ledger audit. The four entries in `contraction.diagnostic_certificates` at manifest line1831 are likewise omitted. These omissions concern mathematical statements already inside the frozen packet; no compiler/native investigation is needed to inventory them.

I recursively compared all `TensorRewrite.*` references in the pilot manifest against the ledger, then confirmed the 30 missing names exist in Lean's imported environment. An independent `ReviewMissingAudit.lean` successfully `#check`ed and axiom-audited all30. Only standard `propext`, `Quot.sound`, and `Classical.choice` occur. The JSON companion lists every name and its original manifest field.

Correction: register these declarations with their precise mathematical kinds/profiles, or publish an explicit mathematical exclusion partition and narrow the inventory claim. The current **319 registered** count is numerically accurate; it is not a complete inventory of retained mathematical evidence. Adding omitted certificates must not imply benchmark correspondence or record closure. The four separately audited library integration theorems should remain separately identifiable.

### MF-02 — P2, bookkeeping: numerical refutations counted as correctness-proof R

`tools/check_theory.py:70` categorizes all of `ConvolutionFloat.lean` as R. This includes `binary32_fold_omission_refuted` at lines59–63 and `binary32_reversal_refuted` at lines66–71. Those are eleven code lines, supported by the certificate-only local notation at line56 (one additional line). `docs/lean-size-protocol.md:76` explicitly requires counterexample certificates to have their own subtotal rather than correctness-proof R.

Consequently `census/convolution-ordered-v2.json`'s `/new_category_lines` and `reports/ordered-convolution-numerics.md:35–36` charge the new certificates to R while leaving C at its historical337. The ledger correctly calls the two new statements numerical refutations; source-size attribution does not follow that distinction.

Correction: separate or explicitly account for these certificate/support lines in C and regenerate affected categories/manifests/reports through a new integration. A module split can add imports/scaffolding, so recalculate the physical total if the sources change. **The existing4165 total is correct**; this is category misattribution, not missing source lines.

Neither finding refutes an inspected theorem. No mandatory mathematical premise was found silently promoted into a broader result. The remaining semantic boundaries below are explicitly limited claims, not additional accusations of false mathematics.

## Frozen identity, isolation, and replay

Target commit: `9bcd44756cbf5261a0c690e05651e96fa162319a`.

- Archive SHA256: `13fe06df530361d295f70127eeaf8d2de48d6b0393385b88e687943a2b67e435`.
- Manifest SHA256: `52006ae61a174033ec8584540279ea03082686618393b05886a87ee4cd40a4b6`.
- Fresh extraction: `/tmp/math-foundation-review-otji_e3w`.

I verified the descriptor hashes, all268 manifest member sizes/hashes, exact zip membership and safe member paths. All267 members marked committed mathematical snapshot also match their blobs at the target commit, independently of the later integrator checkout. The remaining member is the review brief. After reproduction, all268 extracted members remained byte-identical to the frozen manifest; only scratch probes/logs/build outputs were added.

I read the extracted AGENTS.md and scope/protocol documents. The extraction's `.lake/packages` symlinks to the existing project dependency directory. All ten Lake manifest revisions and clean tracked sources were verified before and after reuse. Dependency sources and compiled caches, and the installed Lean4.35.0 toolchain, were reused; **this project's build outputs were not copied**. This is a clean project replay, not a fresh compilation or independent semantic audit of upstream libraries. The integrator's separate clean replay was not used as a review oracle.

The following commands actually ran from the extraction, all with exit code0:

```sh
python3 tools/check_libraries.py
python3 tools/check_theory.py
python3 tools/check_logical_family.py
python3 tools/check_convolution_model.py
python3 tools/check_convolution_pointwise.py
python3 tools/check_convolution_dot.py
python3 tools/check_convolution_separable.py
python3 tools/check_convolution_ordered.py
python3 tools/mathematical_ledger.py
python3 -m unittest discover -s tests -p 'test_convolution*.py' -v
python3 -m unittest discover -s tests -p test_logical_family.py -v
python3 -m unittest discover -s tests -p test_mathematical_ledger.py -v
lake env lean ReviewGeometry.lean
lake env lean ReviewInventory.lean
lake env lean ReviewMissingAudit.lean
```

The unit-test totals are16 convolution +4 logical-family +3 ledger =23. The JSON records elapsed times, log hashes, exact command arrays, dependency revisions, probe sources, and additional Python integrity/counting checks. Initial sandbox startup failed with a bwrap network-namespace error; the checks were rerun through the approved execution path. No native/source-analysis command, unfiltered test suite, or checkpoint.py was run.

## Eight-part mathematical inspection

1. **Actual definitions, types, shapes, and indices.** I inspected all22 `TensorRewrite/Theory/*.lean` files and their89 registered statements, including definitions and proof bodies, plus the project tensor, finite-product, linear-index, contraction, reduction and selected guard/observation dependencies listed in the JSON. `Shape rank = Fin rank → Nat`, `Index shape = (axis : Fin rank) → Fin (shape axis)`, and tensors are total functions on legal coordinates. Rank zero has one coordinate; a zero extent makes the coordinate type empty. Existential legal positions justify divisions in decoding, rather than requiring hidden global positivity premises. Empty-result equalities are correctly vacuous value equalities, not claims of nonempty output.

2. **Logical family.** The closed typed `Rule` vocabulary admits12 predicate and8 word profiles, the latter universally over natural widths including zero. `rewrite_sound` preserves pure tensor values; `xorEqual` requires equality of the two input tensor values. True-constant constructors cannot inhabit word domains. `allRules_complete`, `allRules_nodup`, width-key uniformity and12/8 counts have the claimed types and proofs. Completeness is relative to that declared vocabulary, not all possible logical identities or all benchmark records. At width zero several functions coincide; the20 figure correctly counts profile units rather than distinct functions. The negative controls reject word32/predicate-True misuse and false xor true = false.

3. **Exact convolution.** `Axis.outputExtent` derives output positions from signed padding and dilated extents, using Euclidean integer division by the positive stride and clamping the final integer count at zero. `inputIndex?` admits only nonnegative occupied base-dilation positions with bounded quotient. High padding changes output extent; low padding changes sampled positions. `term` contributes the additive zero on invalid samples; channel and spatial kernel positions are explicit. Group/batch and group/channel indices are flattened by bounded products, while kernels/output retain group axes. This is a coherent declared factored model, including independent group counts and zero groups; I did not assume it is a normal form for an external operator. Empty input, empty kernel, and zero channels are separate cases. An empty kernel can leave nonempty output positions with an empty sum. The Semiring laws justify zero/algebra/scaling results without commutative multiplication.

   Beyond the packet's22 finite vectors, my reviewer probe evaluated2160 axis configurations: input/kernel extents0–2, stride/base/kernel dilation1–2, low padding−2–2, high padding−1–1, both reversal choices. A Python oracle independently counted translated windows by a containment inequality and looked up occupied input coordinates, using neither quotient nor modulo. All5968 sample comparisons and all2160 output counts matched. This is finite corroboration, not universal proof.

4. **Pointwise/channel and matrix Dot.** The five pointwise premises derive output=input spatial shape and a unique spatial kernel coordinate, even at rank zero or empty input extent. `channelSum` genuinely has no spatial-window loop, optional sample or padding arithmetic; `sum_kernel_positions` changes the actual domain to `Fin C`. Its single-channel bare-product theorem correctly assumes Semiring. Dot uses A[B*S,C], W[O,C], result[B*S,O] separately within each existing group pair. The row is `b*S + linearize(x)`. I checked both coordinate inverses and both value directions, including their zero-size boundedness behavior. The exact Dot bridge uses additive laws to relate its ordered fold to an exact finite sum; it does not supply rounded numerical laws.

5. **Mixed-window reduction/reversal.** `IsSeparableAxis` requires unit stride/base/kernel dilation, zero padding, and kernel-one or output-one independently per axis; the theorem additionally requires one input channel. Equal spanning input/kernel extents are derived from output-one, including the zero/zero case. `ReducedIndex` removes unit kernel axes and the sole channel. Expansion/projection inverses, selected reversal involution, full kernel/linear-position equivalence and their composition cover the complete original contribution domain. The term proof moves reversal onto the kernel while leaving multiplication operand order intact. Reindexing uses exact commutative addition available from Semiring. Rank zero/all-unit kernels have a singleton reduced domain; a retained zero extent gives an empty domain. No general floating reversal theorem follows.

6. **Ordered and binary32 contracts.** L, R, Acc and Result are independently quantified types; multiplication has type L→R→Acc, addition Acc→Acc→Acc, and finish Acc→Result. Padding is an explicit accumulator contribution, not implicitly a floating input zero multiplied by the kernel. The pointwise theorem never observes padding. `term_eq_dot_product` aligns the same numeric list position; `terms_eq_dot_terms` proves literal ordered-list equality, rather than only a permutation or equal sums. Both value directions preserve exactly the supplied operations, initializer and finish. The one-channel result is `finish(add(initial,multiply(input,kernel)))`.

   `binary32_pointwise_dot` specializes identical separate product/add folds with identity finish. Its all-operand stored-value equality includes modeled exceptional encodings because the computations are preserved, not because an IEEE algebra instance is assumed. `binary32_reference_eq` reuses pinned FloatLib scalar reference equalities for the same initializer/padding and identity finish. The fold-omission witness gives +0 versus −0, words0 and0x80000000. Folding [2^24,1,−2^24] gives0; reversing it gives1, word0x3f800000. These are valid scalar/fold refutations under the stated observation contract. No theorem connects their candidate labels to source rewrites or external schedules. Flags, FMA, changed cast placement, arbitrary backend orders and physical layouts remain outside the positive claim. The partial older exceptional-multiplication, ordered-NaN and zero-MAC relations are deliberately necessary-condition profiles, not complete arithmetic specifications.

7. **Controls, oracles, and failed history.** I inspected the mathematical checkers, Lean convolution fixtures, negative fixtures and23 targeted tests. The pointwise controls cover8 profiles/78 outputs, Dot11 profiles/220 comparisons in both coordinate enumeration directions, mixed-window11 profiles/123 outputs, and ordered12 rank-zero binary32 profiles plus a heterogeneous nonassociative fold. Both actual Lean formulations are evaluated and compared with independently implemented Python expected values; repeating an expected value in two expected columns does not make these checks circular. The shared general integer oracle is not an independent proof of its own geometry formula, which is why the separate reviewer probe used another formulation.

   The binary32 oracle uses exact rational arithmetic and nearest-even encoding with explicit signed-zero handling. It intentionally rejects nonfinite decoding, specifies no NaN policy, and is not a general oracle for folds after an overflowing intermediate. The current finite profiles remain within its domain. The exceptional-encoding universal theorem rests on preserved computations and the library interface, not exhaustive numerical controls. I verified the failed-v1 zip hash and its internal source manifest. Every nonchecker source is unchanged in v2; differences are the manifest version and the documented regex string-versus-tuple parsing/indexing correction. The failed v1 was not promoted into an accepted replay.

8. **Audits, pins, counts, and attribution.** All319 registered declarations successfully replayed `#check`/transitive-axiom audits, and all89 theory statements are present in their registered audit. Four integration theorems are separately audited. Standard dependencies are only `propext`, `Quot.sound`, and `Classical.choice`; some proofs have none. My imported-environment inventory found no project axiom declarations, and the custom source scan found no custom unsafe/extern/implemented_by declarations. MF-01 concerns explicitly retained declarations omitted from registration, not an unapproved axiom found in the registered closure.

   I independently counted all106 project Lean files using the packet's lexical counter:4426 lines, including261 in `Pilot/Audit.lean`, which is correctly excluded as separately measured audit code. The development subtotal is therefore4165 =2763 historical baseline +33 library integration +1369 theory extension. The theory extension has S355/H571/R433/A10 as frozen; MF-02 corrects its certificate classification. All custom model, support and root/adapter code is charged. Imported Mathlib/FloatLib code is disclosed and not charged as new experiment code. The4165 figure includes certificates and is not certified as correctness-proof-only L. This inspection does not establish first-accepted sizes or dependency-closure cost attribution for every older rule.

## Boundaries and disposition

The source/target identity checks, clean project replay, all89 foundation statement inspections and the two identified bookkeeping defects are concrete review results. The JSON separates files inspected semantically from declarations audited mechanically. I did not completely rereview the semantics of every older pilot theorem or every retained abstract benchmark recipe, nor independently verify entire upstream library proofs/cache provenance or Lean's compiler/kernel implementation.

No compiler source, C++ extraction/matcher/caller audit, native fixture/result, external XLA investigation or compiled-implementation proof was opened or run. Historical source/native descriptions inside retained documents were treated as unverified provenance. Broader padded-numerical, conversion, layout, observation and composition partitions remain unproved where explicitly documented.

The corpus remains488 retained records:405 awaiting formulation/domain partitions,71 with partial model evidence,12 carrying the declared logical-value family. Whole records closed remains0. Mathematical N/F and the full workflow verdict remain open. Correct MF-01 and MF-02 in a separately recorded integration; this report changes no packet, theorem, protocol, acceptance status or benchmark correspondence claim.
