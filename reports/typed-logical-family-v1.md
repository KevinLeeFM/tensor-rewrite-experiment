# Complete typed logical-value family

The declared mathematical family has20 profiles:12 predicate identities and8
arbitrary-width word identities. The word width is universally quantified, not
bounded by testing a few widths. All tensor ranks/extents are allowed; scalars,
zero-width words and empty tensor dimensions are included.

Eight rule templates support predicates and words: double logical negation,
left/right zero conjunction, left/right zero disjunction, left/right zero XOR,
and equal-input XOR. Four further True-constant identities are predicate-only.
The XOR equality premise is an actual part of the theorem. Floating-point values
are not domains of these logical operations. Pure tensor values are the observation.

The family publishes its own typed expression semantics and closed rule grammar.
`rewrite_sound` proves preservation for every admitted rule and every input
environment satisfying the stated side condition. Separate certificates prove
complete and duplicate-free enumeration, exact domain-specific counts and
width-uniformity of the word obligation keys. No new project axiom, sorry or
native_decide is introduced; printed dependencies are standard Lean axioms only.

The20 profiles overlap the previous20 individual Boolean/bitvector value laws.
They are not20 new mathematical rewrite discoveries. Six new soundness/enumeration
certificates and a coherent formal contract establish model-family completeness.
Old pilot statements and historical acceptance fields remain unchanged.

## Evidence and negative controls

- `census/logical-values-family-v1.json` freezes the mathematical model/proof hashes
  and20 member profiles. It is not a full-workload denominator.
- `reports/logical-values-family.json` records all profiles, certificate axioms,
  checked enumeration output and negative controls.
- `InvalidLogicalWordTrue.lean` is rejected because predicate True has the wrong
  domain for a word32 rule.
- `InvalidLogicalXorEqual.lean` is rejected because false XOR true is not false.
- Four family-accounting tests reject missing/duplicated profiles, a word True
  rule, an erased XOR side condition and false whole-workload closure.
- Three existing mathematical-ledger tests continue to pass. No C++ or native
  pass investigation is performed.

The ledger now audits248 registered declarations. It retains all488 benchmark
records:12 have a complete declared pure logical-value family attached,62 have
other partial model evidence and414 lack attached evidence. These counts do not
establish12 whole-record successes or a74/488 verification rate. Mathematical
partitions beyond this declared family and independent statement review remain
open. Code correspondence stays future work under the user-amended scope.

## Artifact size

This milestone adds130 code lines:102 semantic-model lines,27 rule/certificate
lines and one root import. Combined custom Lean totals3037:
S878/H978/R773/A71/C337. Test/audit code and the Python family checker remain
separate from these categories. The previous individual proofs are preserved;
future consolidation must preserve their contracts and axiom gates.

The default theory target now has18 registered theorem statements. Build, theory
axiom audit, family checker,248-declaration inventory audit and seven mathematical
accounting tests pass. This is not the final independent replay or a full-campaign
verdict. The next step is to formulate further mathematical domain partitions,
complete the diverse pilot and proceed through all remaining benchmark families.
