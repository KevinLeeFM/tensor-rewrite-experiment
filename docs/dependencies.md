# Library-backed baseline

Lean: **4.35.0**, fixed by `lean-toolchain`.

| Direct dependency | Selected version | Purpose |
| --- | --- | --- |
| Mathlib | v4.35.0; `56a005855ea17e0b0958f73ec801ae140b0a1679` | Algebra, finite sums, indexing and proof tactics |
| FloatLib | `acba2057e452f32f4ed4f06bb0adbeda5342ba92` | Executable scalar arithmetic and reference-refinement proofs |

`lake-manifest.json` locks direct and transitive revisions. Do not edit an upstream
checkout to make a proof pass; record any required patch as experiment-owned code.
Imported third-party code keeps its upstream license and attribution.

## Fresh setup

Install elan/Lean, Git and Python 3, then from this repository:

```sh
lake update
lake build
python3 tools/check_libraries.py
```

Mathlib's update hook downloads its compiled cache. `.lake/` is generated and
excluded from Git. FloatLib modules compile as imported. The default build includes
the historical `TensorRewrite` development, `TensorRewriteLibraries` integration
and `TensorRewriteTheory` mathematical proofs.
The historical native XLA experiments additionally need their pinned external
checkout, Bazel and parser dependencies; see README.md and the source manifests.
They are separate from the Lean dependency setup.

## What the integration establishes

`TensorRewrite/Libraries/Arithmetic.lean` exercises checked integer algebra.
`TensorRewrite/Libraries/FloatingPoint.lean` proves binary32 addition/multiplication
agree with FloatLib's reference operations and lifts addition to arbitrary-rank
tensors. These imported refinement theorems compare stored values, including
exceptional encodings. They do not observe exception flags, establish XLA source
correspondence or validate unrestricted floating-point reassociation.

`tests/fixtures/LibraryAudit.lean` prints transitive axioms for all four new
theorems. The checker permits only standard Lean axioms and records the results,
source hashes, dependency revisions and new integration lines in
`reports/library-setup.json`. This is validation of the selected import closure,
not an independent semantic audit of every theorem in the upstream libraries.
The historical pilot replay and all 68 Python tests also pass; see
`reports/library-regression.json` and its archived logs.
No unchecked host-FPU execution path is selected by this integration.

## SSA framework compatibility

Lean-MLIR was inspected at `b8c4a771319a044854a4bbb49b8821381ef86ff8`.
Its root toolchain is `nightly-2025-12-01`, incompatible with this pinned workspace.
It is not a Lake dependency here. Existing project DAG/context proofs remain usable.
A future SSA-framework integration needs a separately validated compatible revision
or an explicit port; changing the experiment's toolchain is a separate measured step.

## History, size and portability

Commit `04d01d6` preserves the experiment before library dependencies: the original
Std-only Lean pilot and all previously collected evidence remain available. New
integration modules count as category A; imported library code is disclosed rather
than charged as new experiment code. The previous pilot's 2,763 lines remain a
historical subtotal. Read `reports/library-setup.json` for that checkpoint subtotal. The later
mathematical target and current total are audited by `tools/check_theory.py`
and recorded in `reports/theory-progress.json`.

The planning protocols in this directory were copied from the original research
notebook on 2026-11-10. Their historical notebook-relative links retain that context;
README.md, this document and the checked-in tools provide standalone build guidance.

## Reuse in exact scalar domains

The existing Mathlib pin also supplies real log/exp/sqrt, principal complex
logarithm/square root and norm-square identities. The scalar-domain milestone
uses those to derive necessary/sufficient complex domains and pointwise tensor
lifts, with two explicit counterexamples. No additional dependency or toolchain
change was needed; see [the exact scalar-domain guide](scalar-domains.md).
These analysis functions do not model rounded executable transcendental functions.


## Reuse for singleton state transport

The covered-window/singleton-tuple milestone reuses the same pins. Generic state
transport and the outer tuple proof need no scalar algebra law; FloatLib supplies
actual binary32 addition and stored-bit observations without changing fold order.
Mathlib supplies finite-index and coordinate reasoning for the explicit Reshape/
Broadcast graph. See [the proof scope and controls](broadcast-window-and-tuples.md).
No additional SSA framework is installed or implied by this reuse.
