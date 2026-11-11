# Whole-corpus mathematical proposals

Every retained record now has a domain/dependency worksheet. This checkpoint adds
380 explicit record proposals in seven new worksheets; it adds **no accepted Lean
statement or proof**. The previous108 records already had worksheets. The new
catalog v2 reconciles all488 unique IDs, with the31-record window refinement of
reduction counted once. Catalog v1 remains unchanged for historical replay.

| New worksheet batch | Retained records |
| --- | ---: |
| Simple |51|
| Arithmetic |85|
| Scalar/control |55|
| Shape |58|
| Tensor indexing |57|
| Layout |30|
| Dot and construction/support |44|
| Total new proposals |380|

## What each proposal records

Each row preserves its exact retained lhs/rhs, names candidate mathematical domains,
states a target and explicit mathematical premises, records concrete remaining
partitions and retains candidate evidence from base revision `22cb0da`. It requests
arbitrary legal finite ranks/extents and all values in each admitted profile;
finite-word widths are not replaced by a handful of samples. Target shape and
bounded coordinate maps remain conclusions to derive, not sample-equivalence
assumptions. The380 rows are assigned explicitly, without wildcard/default admission.

The124 classification groups and38 domain descriptions organize proposals; they
are **not** mathematical F or N. The domain descriptions do not install new Lean
operator axioms or claim that their semantics already exist. Existing evidence
for73 of these records remains candidate evidence with its original scope. No
record becomes verified because it gained a worksheet.

`census/formulation-evidence-baseline-v1.json` preserves the candidate references at
that base revision, so later proof additions do not silently rewrite this packet.
`census/mathematical-domain-proposals-v1.json` marks all38 domains as unreviewed and
not accepted as full semantics. The seven immutable worksheets and their generator
are pinned in `census/workload-formulation-expansion-v1.json`. The generator refuses
to overwrite existing inputs. Changes to a frozen proposal require a successor.

## Distinctions that affect the workload

The new packet identifies four construction/context support schemas and two
transformation stages, alongside352 candidate transformation schemas and22 records
with delegated/unspecified targets. Twenty-three records have an unspecified-target
risk because one construction-support schema is also missing an old-operator meaning.
Equal byte size or SameShape cannot prove an arbitrary replacement preserves values.
These records remain in the corpus, but must not automatically count as individual
correctness obligations. Denominator review must resolve support/stage overlap and
split genuine dtype, shape, option and observation partitions.

Several concrete hazards remain explicit:

- Exact ring/field identities do not supply IEEE reassociation, annihilation,
  distributivity or reciprocal-literal laws. NaN, infinity, signed zero and rounding
  require independent scalar observations and domains.
- Nonnegative comparison profiles distinguish unordered Lt=false from Ge=true.
  A recognition predicate or option label is not adopted as an algebra axiom.
- Scatter needs actual reducer parameter roles and duplicate-update ordering;
  an Add-shaped root may use p0+p0 or p1+p1 instead of p0+p1.
- RNG shape rewrites need an independent distribution and/or state/stream contract.
  Equal element count does not establish those observations.
- Empty Gather input does not define a nonempty output as zero. Derive empty output
  from legality or specify the missing empty/out-of-bounds behavior.
- Ordinary Slice transformed bounds retain known empty-interval counterexamples.
  The scaled nested DynamicSlice target retains its discarded-multiplier case.
  A nonempty or multiplier-one repaired profile cannot replace the original case.
- Principal complex sqrt/log/power branches stay distinct from exact real analysis.
  Physical bitcast/copy needs actual bitstream/layout maps and observed transfer,
  allocation or alias behavior; pure Copy-as-identity would omit that contract.

These are mathematical proposal/dependency diagnoses. No C++ extraction, helper/API
correspondence audit or native pass investigation was performed. Related explicit
helper schemas can suggest candidate mathematical graphs, but correspondence is
not certified by selecting one. Code correspondence remains user-deferred future work.

## Validation and what remains

Run `python3 tools/check_formulation_expansion.py` and
`python3 tools/workload_formulation_audit.py`. The first checks frozen input identity,
exact proposal membership, retained expressions, domain references, historical
evidence and no-acceptance flags. It **does not judge mathematical correctness**
of the prose. The second reconciles all488 IDs and reports380 records covered only
by the new unreviewed proposals, zero missing worksheets and zero evidence records
without a worksheet. It continues to reject treating worksheet presence as completed
formulation or a complete proof attempt.

Pinned Lean build/axiom replay and all80 focused tests pass; exact logs and commands
are in `reports/formulation-expansion-validation-v1/`. Tests preserve historical
catalog108/380 counts, distinguish the new488/0 catalog, retain counterexample and
missing-operator partitions, and reject omitted IDs, source drift or invented
proof/semantic-review/denominator acceptance.

Lean totals remain341 theory statements,601 ledger declarations and7,547 custom
lines (S1711/H2974/R2152/A88/C622), with four integration results separate. The new
Python/proposal artifacts are tracked separately; zero new Lean here does not mean
zero unknown burden for the remaining models/proofs. Complete declared value
profiles remain21. Record statuses stay351 needing formal statement/domain work,
124 partial and13 carrying declared value families; whole-record closure remains0.
The252 later theory statements and these new proposals await independent review.

Next turn the proposals into precise typed operator meanings and statements,
reconcile the mathematical denominator, execute every required proof/domain attempt,
revisit residuals with shared support and alternate strategies, diagnose representative
failures and perform independent statement/replay audits. The comparison and final
exit gates in the experiment plan remain required. Mathematical N/F and a qualified
positive/negative workflow verdict are still unresolved.
