# Independent final review

Disposition: **accept one exact frozen mathematical model theorem**, subject to the narrow interpretation and experiment limits below. No remaining correctness blocker found in the inspected final artifact. This does not establish global novelty, a complete native source branch, compiler correspondence, general LLM productivity or speedup.

Reviewer: candidate_review, separate from coordinator/specification author and fresh-history proof worker. Final-review UTC start 2026-11-17T01:59:20.596440+00:00, end 2026-11-17T02:01:54.681118+00:00, observed interval 154.084678 seconds including file inspection, integrity commands, reasoning, messages and writing. No new Lean builds were run by this reviewer. Coordinator's fresh replay output was inspected; independent execution of the kernel replay by this reviewer is not claimed. Only this final-review file was edited in this stage.

## Frozen input and proof acceptance

Read actual Spec, Proof, corrected Guard, Witnesses, Audit, replay.py, protocol, development ledger, frozen manifest, all negative controls and fresh replay evidence. A read-only hash check confirmed **every** frozen input matches both its manifest digest and the preproof Git commit a6ea7403e7b65c71e5715d3dd02421ff2685ca5c; pinned local source bytes match the manifest too. Thus the accepted proof did not silently change the specification, two-file baseline, guards or frozen controls. The exact final Proof SHA agrees with the proof worker's ledger.

Proof.reverse_reshape declares exactly `: Goal`, introduces all frozen quantifiers, extensionalizes tensor/index functions and proves retained-coordinate equality. It splits on unit extent and selected mask. In the unit case the coordinate bound forces zero; otherwise the extent cast preserves ordinary reversal arithmetic. No new assumption, changed guard, imported historical solution, target-specific helper, new axiom, native_decide, sorry/admit or unsafe override occurs in the actual accepted proof. It imports only Spec and Guard. The source is short but not definitional reflexivity of an equality-assumed specification.

The proof uses only retained-extent agreement; plan monotonicity and complement-unit fields certify the interpretation as an order-preserving unit insertion rather than doing substantive work in the coordinate equality. This is useful disclosure about difficulty and abstraction. It is not a reason to infer that general native reshapes commute with reversal.

Coordinator's clean replay checks the exact elaborated type against Goal, reports theorem axioms [propext, Quot.sound], and repeats both checks in Audit. These are permitted Lean foundations. The control-refutation axiom report has the same two foundations. The initially failed proof attempt contains sorryAx diagnostics with a nonzero exit; that artifact is recorded as failure and is not accepted proof evidence.

## Scope and boundary audit

Accept only the arbitrary-rank, arbitrary-value, natural-extent **logical unit-insertion-only partition** of HandleReverse/inserted-unit-dimensions reviewed previously. Projection interpretation of reshape, order-preserving native retained-axis extraction and list/mask axis-remapping correspondence remain disclosed translation assumptions. No C++ correspondence, helper-recognition completeness, pass execution/reachability, metadata, layout or effect result follows. In particular the native helper's >1 tests can recognize zero-sized modified gaps, while this model requires inserted dimensions exactly one.

The unchanged UnitInsertion structure admits retained zero extents and scalar rank without adding positivity premises. Actual Audit constructs a scalar-to-two-unit-axis plan, proves the scalar coordinate domain inhabited using the corrected dependent function `fun i => Fin.elim0 i`, and specializes the theorem. It separately constructs [0] to [1,0], proves input coordinates uninhabited and specializes the theorem. The zero case is legitimate emptiness, not the nonvacuity witness for the general result.

Witnesses constructs [2,3] to [1,2,1,3,1] with retained axes [1,3], input x(i,j)=10*i+j and reversal of output axis one. The original observation is 10, wrong unadjusted-axis remap gives 2, and omitting reversal gives 0. These are kernel-evaluated using ordinary decide, with a separate proof of negation of WrongGoal. Thus the main specification has a meaningful nonempty instance and the deliberately wrong replacement is provably false.

The finite Python row-major/remapping sanity check enumerates 187 plans, 2,127 masks and 4,675 observations, including 76 empty and three scalar plans, with zero mismatches. Its source is independent of the Lean proof and compares literal source-loop remapping against the abstract retained-axis map and row-major observations. It supports source transcription confidence only, not exhaustive C++ correspondence or native execution.

## Isolation and negative controls

The corrected Guard now compares against 11 exact baseline names, including the observed generated axisMask._proof_1; the previous namespace-wide exception has been removed. The case-local namespace remains allowed, which is appropriate for new proof declarations but is not by itself a sandbox. Frozen source/import hashes, the proof-import/code scan and this actual-content review jointly supply the isolation evidence.

The runner sets a fresh build-only LEAN_PATH for baseline/spec/proof/audit. It compiles the forbidden module into a separate control path after the successful proof/audit. A read-only byte comparison confirmed controls/Forbidden.lean is an exact copy of the original quarantined TensorRewrite/Pilot/IndexLemmas.lean. Its successful compilation establishes a real well-formed contamination source. LeakTrial then exits nonzero specifically with HELDOUT_BASELINE_LEAK for TensorRewrite.Pilot.Tensor.reverseIndex_reverseIndex, rather than failing to import or parse.

FalseTrial imports the well-formed, separately refuted WrongGoal and fails on intended rfl/non-definitional equality, not syntax, missing names or missing decidability. SignatureTrial passes an existing theorem of the wrong proposition to the exact-type checker and fails with HELDOUT_SIGNATURE_MISMATCH. These establish the advertised controls for this artifact; no universal malicious-input isolation guarantee is claimed.

The runner verifies pinned compiler version, frozen inputs/source hashes and allowed imports; rejects disallowed proof constructs; requires clean successful exits; audits the axiom reports and exact signature; and requires intended nonzero control diagnostics. Its regular-expression source scanner is not a formal Lean parser or comprehensive adversarial detector. It is adequate here combined with manual inspection of the actual small proof. replay.py and final Audit are postproof validation tools rather than frozen pre-outcome trial inputs; do not describe them as preregistered. No broad build/download is performed by replay.

## Failures and time interpretation

Proof-development ledger records 125.490361 seconds inclusive wall time, three compile attempts totaling 2.567175 seconds, and a missing installed Std source-tree search. The first attempt failed (dependent rewrite, a generated declaration guard diagnostic and command syntax); second passed with unused-simp warnings; third passed after warning cleanup. These are retained failures/iterations within one bounded proof attempt, not three independent successful cases. Development minus measured compiler durations is reported as overhead-inclusive development time, not pure reasoning or model compute.

The first coordinator replay passed the target theorem, signature and axioms but failed the scalar Audit witness's dependent-function typing. Original Audit and failure JSON are preserved. Its recorded compiler subprocess durations total 4.088122 seconds; this is validation infrastructure failure, not target-proof rejection. The corrected scalar witness changes no frozen input or target proof.

The second fresh replay completed all 12 success/negative-control subprocesses in 6.254842 seconds (2026-11-17T01:59:31.777941Z to 01:59:38.032764Z). Proof replay itself took 0.767622 seconds. This replay time is distinct from proof development, specification/setup, earlier compiler installation and reviewer intervals. Do not add nested compiler times again to enclosing wall intervals or infer a speedup from historical replay timings. Exact model/resource/token figures remain unavailable.

Earlier statement review and final proof review are independent human-style inspections by an agent, not a certification that the repository-wide target is globally novel. Existing scoped overlap audit located no equivalent terminal theorem among relevant project/paper/fixed-tactics statements. No matched automated baseline was measured for this target; no comparative productivity conclusion is supported.

## Reviewed final byte hashes

- `Spec.lean`: `9dc5af1030818e6bbdd54835b73ff34fa6382ed7d6a574b558e8e84bb049afea`
- `Proof.lean`: `a70d794b2c5e58d2de029bda2e8e4c8ac3945cabef2c996307077f42504299a0`
- `Guard.lean`: `f8925693434b681be715b3375ab70865fce6bb856fa9eb3276b009f796c7a743`
- `Witnesses.lean`: `4f83db38b52d412c318ac487d207c5fe788d3aa8df6f5d68a0c2ef8c72f93bf8`
- `Audit.lean`: `de4b522e214b16f9176e3b6fdd7e5b3468cbf2f0719ffc35d6e1504b4cc2d4a8`
- `replay.py`: `6a479445b154990bc39cf0f45870b63d2c641bc00e7405f44e66e6f5771555c9`
- `frozen-manifest.json`: `c6eff37864b09c72fdb33cb94877b5978f2776f2bfb263967220f18f12a9f64e`
- `proof-development.json`: `cd62c0eeb860b3bdbab1f5764aaabd4d85cd37710ad5fe510c25924c0b0f5c1d`
- `cloud-replay.json`: `42e510f74107327bc1d90a3f74cb4e84d1eb15291fb8f72dbfc35a0e351510cb`
