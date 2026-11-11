# Mathematical family acceptance and counting

A family has a versioned mathematical contract: its domains, expression meaning,
rule vocabulary, side conditions and observations. Its published member list must
be complete and duplicate-free under that contract, and every admitted rule must
have a kernel-checked preservation proof or a separately recorded refutation.

This closes the declared model family. It does not close every retained benchmark
record, establish code correspondence or settle the full experiment. Labels from
the retained corpus remain candidate associations. Independent statement review
and the diverse-pilot/full-campaign requirements remain active.

## Typed logical values, version1

Model: `TensorRewrite/Theory/LogicalFamily.lean`.
Certificates: `TensorRewrite/Theory/LogicalFamilyProof.lean`.
Frozen contract/profile manifest: `census/logical-values-family-v1.json`.
Checked result: `reports/logical-values-family.json`.

There are12 predicate profiles and8 word profiles, with each word profile
universally quantified over all natural widths. Arbitrary finite rank, all natural
extents, scalars and empty tensors are included. Eight mathematical identities
apply to both domains; four True-constant identities apply only to predicates.
The equal-input XOR identity requires equality of the two tensor values.

The complete count is20 mathematical profile units, associated with12 benchmark
labels. Twenty is not a new distinct-rewrite count: the earlier Boolean/bitvector
pilot already proved these identities individually. The typed family and its
coverage certificates organize that content and prevent omitted-domain or omitted-
premise accounting errors. Not all logical operators/compound identities in the
retained collection belong to this family.

Observations are pure tensor values. No graph scheduling, effects, layout,
exception flags or implementation semantics is included. Float values are not
logical-operation domains. Bitwise word operations cover all widths without
assuming that the word constant1 acts like predicate True.

## Required evidence

The logical family has a universal `rewrite_sound` theorem, an `allRules_complete`
certificate, duplicate-free enumeration, exact12/8 count certificates and a
width-uniformity certificate for published word-profile names. The checker derives
the profile list from Lean evaluation and validates the immutable model hashes.
A word32/predicate-True type mismatch and unequal-input XOR rejection are required
negative controls. The ledger rejects erased side conditions, missing/duplicate
profiles and promotion of family completion to whole-workload completion.

Run:

```sh
python3 tools/check_theory.py
python3 tools/check_logical_family.py
python3 tools/mathematical_ledger.py
python3 -m unittest discover -s tests -p test_logical_family.py -v
python3 -m unittest discover -s tests -p test_mathematical_ledger.py -v
```

`--freeze-family` is only for first publication. Existing v1 cannot be overwritten;
model changes require an explicit family-version revision and measurement update.
The full mathematical obligation/family denominators remain open. Future families
must retain hard numerical/layout/effect cases and document all domain partitions.
