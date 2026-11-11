# Independent MF-01/MF-02 correction recheck

Target: **`1f559e20b0bd25148571f86f9fb978a2dd0fed0d`**.

Verdict: **issues requiring correction**. **MF-02 is resolved. MF-01 is partially resolved:** the inventory is complete for the retained explicit references, but two newly added witness descriptions identify the wrong mathematical model. This recheck changes no acceptance field or original review.

## Remaining finding: MF-01-R1 (P2)

`tools/mathematical_ledger.py:123` assigns the `algebraic_refutation` family this profile:

> Concrete nonfinite predicate-product witnesses in the declared partial value relation

It is emitted for `TensorRewrite.Pilot.SelectContraction.false_witness` and `true_witness` in `census/mathematical-ledger.json:4972` and `:5051`. These theorems instead concern **exact mathematical integer list contractions**, with a uniform Boolean Select predicate. `SelectContraction.lean` defines `sum : List Int → Int`, scales the selected branch by2 or3, and compares it with hoisting both scales to6.

The explicit values at `TensorRewrite/Pilot/SelectContractionRefutation.lean:22` and `:28` are:

- True: `branchContraction true [1,1,1,1] = 8`, versus hoisted24.
- False: `branchContraction false [1,1,1,1] = 12`, versus hoisted24.

There are no nonfinite inputs, floating values, predicate-conversion multiplication relation or incomplete exceptional arithmetic semantics in these witnesses. Their Lean statements and proofs are valid; the new ledger metadata is false. The retained pilot manifest's original `algebraic_refutation.profile` already describes the exact-integer model correctly.

Correct the fallback profile, regenerate the ledger and protect these two profile descriptions with a focused regression. The current30 passing tests check reference/count/accounting integrity but do not catch this model-description error. No additional label or benchmark closure should be inferred.

## MF-01 inventory checks

The original319 registered declarations are retained, with exactly the30 originally omitted names added, giving**349**. An independent recursive traversal of the retained pilot manifest finds260 distinct explicit declaration references; every name is registered and every `retained_manifest_paths` list matches its true origins. The30 additions have empty candidate-label lists, all prior label lists are unchanged, and no correspondence field is promoted. The benchmark records themselves and status counts are byte-for-byte equivalent as parsed data to the frozen ledger's records.

The regenerated complete audit successfully checks the types and standard-axiom dependencies of all349 registered declarations. The four library integration theorems remain separately audited and disjoint from this registry. The other newly added family profiles preserve their declared partial/diagnostic limits. Inventory completeness and audit registration therefore resolve the omission itself; MF-01-R1 prevents closing the requested precise-profile response.

## MF-02 accounting checks

The unchanged `ConvolutionFloat.lean` hash is bound by `census/lean-category-overrides-v1.json`. Its physical regions1–55,56–71 and72–73 cover the entire73-line source once, without gaps or overlaps. Independently applying the lexical counter yields R39/C12/R1. The C region contains both counterexample declarations (eleven code lines) and their exclusive local notation (one line).

`census/convolution-ordered-accounting-v1.json` validates hashes of the original frozen v2 measurement and the override manifest, and explicitly supersedes category metadata only. The original frozen model remains unchanged. Checked totals are:

| Scope | S | H | R | A | C | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Ordered extension | 30 | 105 | 93 | 1 | 12 | 241 |
| Theory extension | 355 | 571 | 421 | 10 | 12 | 1369 |
| Full custom development, including certificates | 1131 | 1497 | 1112 | 76 | 349 | 4165 |

Thus exactly12 existing lines move from R to C, without changing mathematical sources or total source size. Drift/gap/overlap regression checks pass. **MF-02 is resolved.**

## Isolation, reproduction and evidence integrity

I created `/tmp/math-correction-recheck-u0y0wrxn` from318 selected committed mathematical files, each read at the exact target commit. Its temporary Git metadata has detached HEAD at that commit and uses the original object store read-only. No native/compiler file or untracked integrator `ScalarDomain*.lean` file was included. This is a fresh project snapshot, not a read of the moving integrator sources.

The snapshot began without project build outputs. I reused the existing dependency sources/compiled caches through `.lake/packages`, verifying all ten pinned revisions and clean tracked sources before and after. Upstream libraries were not rebuilt from scratch. All15 independently executed commands passed:

```sh
python3 tools/check_libraries.py
python3 tools/check_theory.py
python3 tools/mathematical_ledger.py
python3 tools/check_logical_family.py
python3 tools/check_convolution_model.py
python3 tools/check_convolution_pointwise.py
python3 tools/check_convolution_dot.py
python3 tools/check_convolution_separable.py
python3 tools/check_convolution_ordered.py
python3 -m unittest discover -s tests -p 'test_convolution*.py' -v
python3 -m unittest discover -s tests -p test_logical_family.py -v
python3 -m unittest discover -s tests -p test_mathematical_ledger.py -v
python3 -m unittest discover -s tests -p test_theory_accounting.py -v
python3 -m unittest discover -s tests -p test_mathematical_review_readiness.py -v
python3 tools/check_mathematical_review.py
```

Focused test totals:16+4+4+3+3 =**30**. I also ran a reviewer-authored independent integrity script and parsed all349 regenerated type/axiom reports; exact commands, log hashes, script and results are in the JSON companion.

Integrity checks passed for all268 original packet members, all106 unchanged project mathematical Lean source files, the immutable original review MD/JSON, all23 members of the archived original reviewer evidence, and all12 hash-recorded correction logs. Original packet archive SHA256 remains `13fe06df530361d295f70127eeaf8d2de48d6b0393385b88e687943a2b67e435`; manifest SHA256 remains `52006ae61a174033ec8584540279ea03082686618393b05886a87ee4cd40a4b6`. Original reviewer evidence archive SHA256 is `97490a5202b27786264d8d0195a7bebadebb7d444d002789ba93547cb367026c`.

The historical readiness verifier still validates its original319-declaration/23-test baseline; it is historical evidence, not the current349/30 count. Relevant committed evidence is `reports/mathematical-review-corrections-v1.{md,json}`, `census/convolution-ordered-accounting-v1.json`, `census/lean-category-overrides-v1.json`, `reports/theory-progress.json`, `census/mathematical-ledger.json`, `reports/mathematical-ledger-audit.{lean,log}`, `reports/library-setup.json`, and `reviews/results/mathematical-foundation-v1-evidence.{json,zip}`. The companion records exact hashes at the target commit.

## Scope retained

This recheck concerns only the two corrections. The original semantic inspection covers the old89-statement foundation; no new mathematical theorem was added, and this is not a complete semantic rereview of all349 declarations, upstream libraries or later extensions. The original review remains unchanged.

All488 retained records remain:405 unformulated,71 partial and12 carrying the declared logical-value family. Zero whole records are closed. Mathematical N/F and the positive/negative full-workflow verdict remain open. No benchmark-label correspondence, source correspondence, native/C++ behavior or compiled implementation is certified. I wrote only this new report and its JSON companion in the shared project.
