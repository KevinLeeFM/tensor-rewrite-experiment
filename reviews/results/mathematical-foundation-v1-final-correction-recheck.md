# Final independent correction recheck

Target commit: **`4273260518b1a37bed5eb69df6512930e728869e`**.

Verdict: **no blocking issue found within the inspected correction scope**. MF-01-R1 is resolved. MF-01 is therefore resolved, and the earlier MF-02 resolution remains valid on unchanged accounting/source evidence. There are no remaining findings from these two corrections.

The two Select witness rows now use the retained manifest's exact profile: “mathematical integer contraction with unit filter and uniform Boolean Select; branch scalars 2 and 3.” Their kind remains `concrete_witness_certificate`; their candidate-label lists remain empty and correspondence remains uncertified. This matches the actual `List Int → Int` definitions and theorem types. A separate Lean probe confirms true-branch values8 versus24 and false-branch values12 versus24, with empty axiom dependencies for both witnesses.

I regenerated `census/mathematical-ledger.json` and confirmed **byte-for-byte equality with the version committed at this target**. Relative to the prior correction commit, the complete parsed ledger changes only those two profile-description fields. No declaration, kind, origin, candidate label, observation/acceptance flag, benchmark record or closure count changes.

The new regression checks the exact retained profile, certificate kind and empty labels. I also ran that regression against the previous committed ledger implementation entirely in memory: it failed on the former wrong profile as expected. This confirms the regression distinguishes the repaired behavior from the reported defect.

All**31** targeted baseline tests passed:16 convolution,4 logical-family,5 mathematical-ledger,3 theory-accounting and3 historical-readiness tests. The ledger's build/type/axiom audit also passed. The baseline remains**349 registered declarations,89 theory statements,4165 custom Lean lines**, with four library integration theorems separately audited.

For isolation, I rehydrated all321 selected committed mathematical files in `/tmp/math-correction-recheck-u0y0wrxn` from the exact commit and set its detached Git HEAD to that commit. I reused the previously verified project build and dependency cache, as authorized for this narrow recheck: all106 mathematical Lean source files remain byte-identical to the original frozen foundation. All ten dependency revisions and tracked-source cleanliness were reverified. This is an incremental correction replay, not a new cold project/upstream rebuild. Later scalar work and untracked integrator files were excluded.

The original packet, original review, original reviewer evidence archive, previous correction review, accounting addendum and category override are unchanged. In particular, MF-02 still transfers exactly12 certificate/support lines from R to C without changing total4165. No prior report or integrator acceptance field was edited.

Commands actually run in the isolated snapshot:

```sh
python3 tools/mathematical_ledger.py
python3 -m unittest discover -s tests -p 'test_convolution*.py' -v
python3 -m unittest discover -s tests -p test_logical_family.py -v
python3 -m unittest discover -s tests -p test_mathematical_ledger.py -v
python3 -m unittest discover -s tests -p test_theory_accounting.py -v
python3 -m unittest discover -s tests -p test_mathematical_review_readiness.py -v
lake env lean final-recheck-logs/SelectWitnessRecheck.lean
python3 final-recheck-logs/validate_final.py
```

The JSON companion embeds the essential new transcripts, Lean probe source, independent Python validator, mutation-rejection transcript and hashes, so this recheck's evidence does not depend on retaining scratch files. Concrete committed evidence is in `tools/mathematical_ledger.py`, `tests/test_mathematical_ledger.py`, `census/pilot-value-proofs.json`, `census/mathematical-ledger.json`, `TensorRewrite/Pilot/SelectContraction{,Refutation}.lean`, `reports/mathematical-ledger-audit.{lean,log}` and `reports/mathematical-review-corrections-v2.md`.

This result closes only the requested review corrections. The original semantic inspection covers the old89-statement foundation, not a semantic rereview of every349 declaration, upstream library or later scalar extension. All488 retained records remain, with zero whole records closed. Mathematical N/F and the full-workflow verdict remain open. No benchmark-label correspondence, C++/native behavior, source correspondence or compiled implementation is certified.
