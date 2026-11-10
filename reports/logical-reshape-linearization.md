# Logical reshape from checked finite coordinates

Source pin: XLA e58e523b11f1fde802a493a776d158007486e1bf.
Contracts and theorem identities: census/reshape-contract.json.
Source acceptance remains0; this extends the mathematical/static logical pilot.

## Source meaning and boundary

The pinned operation_semantics.md:4339–4352 defines reshape through flattening
and refining, with dimensions ordered from slowest to fastest varying and equal
element counts. HloEvaluator::HandleReshape delegates to LiteralBase::Reshape.
The latter (literal.cc:1298–1329) rejects dynamic shapes, relayouts non-dim0-major
input before reusing the value sequence and checks element counts. Shape
inference also has distinct dynamic-dimension handling; it cannot be collapsed
into this static model merely because the element-count equation is available.

HandleReshape first handles empty output, then same-shape elimination and nested
reshape composition (algebraic_simplifier.cc:6911–6946). Empty and composed
replacement paths request control-dependency relay; the same-shape replacement
has its own frontend-attribute behavior. Those graph observations remain outside
the logical value theorems. The source cases retain null proof acceptance.

## Total coordinate semantics and general proofs

FiniteProduct.lean packs a row and column as row*columns+column and recovers
coordinates by division and remainder. Valid finite indices supply the required
bounds. No coordinate exists for an empty rectangle, so unpacking requires no
invented address or default value. Three support theorems prove both coordinate
recovery identities and packing after recovery.

LinearIndex.lean defines arbitrary-rank element counts and recursive dim0-major
packing/unpacking. A scalar has one element and an empty coordinate function.
A zero extent has no complete tensor coordinate and no linear position. Two
inverse theorems cover every finite rank and natural extent without positivity
restrictions or testing a fixed rank bound.

Reshape.lean maps an output coordinate to its logical linear position, transports
that bounded position through the explicit equal-count condition and recovers
the input coordinate. reshapeTensor pulls back values through that concrete map.
reshapeView also supplies this derived rank-changing map to the recognized
constant-guard interface, replacing a caller-chosen map for this wrapper.

Three further support theorems prove uniqueness of zero-element tensor values,
composition of reshape coordinate maps and constant-view preservation. The
three value rules then prove same-shape identity, composition through arbitrary
intermediate rank, and equality with any well-typed zero-element replacement.
All are parametric in element type. They do not perform floating arithmetic;
they preserve logical element values by selecting the same coordinates.

These proofs establish mathematical element counts and logical tensor equality.
They do not establish finite int64 element-count multiplication, raw memory
layout, bitcast legality, dynamic shape behavior or metadata/control/frame
preservation. No result is promoted to those stronger contracts.

## Native evidence and isolation of the intended handler

reports/reshape-replay-v3 contains one native test with five shapes/profiles and
three execution modes per profile: no rewrite, direct HandleReshape invocation,
and one full AlgebraicSimplifier pass. All original/rewritten HLO modules verify.

| Profile | Expected logical output | Direct handler result | Full pass result |
| --- | --- | --- | --- |
| [2,3]→[3,2]→[6], default layouts | 0,1,2,3,4,5 | Direct reshape of input | Bitcast chain |
| Same shape chain, column-major input/intermediate | 0,1,2,3,4,5 | Direct reshape of input | Direct reshape of input |
| Same-shape [2,3] | 0,1,2,3,4,5 | Input parameter | Input parameter |
| [1,1]→scalar→[1] | 42 | Direct reshape of input | Bitcast chain |
| [2,0,3]→[0,6] | No elements | Empty constant | Empty constant |

Nonuniform input labels are set at logical coordinates and relayouted to each
actual parameter layout. Output comparison reads each logical coordinate
directly; it does not call reshape again as the comparison oracle. Lean probes
compute the corresponding full row-major sequence, composed sequence and empty
count, with additional kernel equalities for scalar/empty cases.

Full traversal can simplify producer reshapes into bitcasts before the outer
handler runs. Direct-handler evidence is therefore recorded separately rather
than attributing every full-pass result to the composition branch. The first
v1 archive retained a failed structural expectation: values agreed, but the
test expected reshape where the pass constructed bitcast. V2 separated handler
and pass execution; V3 strengthened output checking to direct coordinates.
Earlier archives are preserved. None is evidence of a value counterexample.

Reproduce with tools/run_reshape_replay.py and an unused reshape-replay-vN
archive. The accepted archive includes the exact source identity, fixture,
BUILD, uncached test command, events, logs, XML and binary hash.

## Validation and code burden

tools/check_reshape_evidence.py checks all15 native observations, source-body
hashes, theorem/source-case identities and actual Lean probe output. Controls
reject promotion to physical/dynamic semantics or source acceptance, omission
of direct-handler cases, and changed logical element order. A false proof using
column-major packing in place of the specified row-major position must fail.
The integrated checkpoint and38 tool/evidence tests pass. All earlier theorem
axiom sets are preserved; new dependencies use the audited standard allowlist.

| Lean category | Previous | Current | Added |
| --- | ---: | ---: | ---: |
| S semantics | 358 | 426 | 68 |
| H support | 323 | 416 | 93 |
| R rule proofs | 292 | 319 | 27 |
| A imports/checking | 19 | 20 | 1 |
| C certificates | 177 | 177 | 0 |
| Total | 1169 | 1358 | 189 |

The increase includes every new packing, index and reshape definition/proof,
alongside the earlier foundations. Test/audit lines are separate in
reports/pilot-values.json. The pilot now has44 value identities,41 support
theorems and the separately counted nested-slice logical rule. Existing graph
rules overlap value cases, so these counts are not source-coverage fractions.

snapshots/reshape-pilot-v1.zip preserves the complete Lean development;
reports/reshape-clean-replay.json records its fresh-directory replay without
build caches and matching measurement, axiom dependencies and index probes.
This is same-agent Lean replay, not independent source review or native rebuilding.

The diverse reviewed pilot still requires reductions and other numerical,
physical-layout and effectful cases. Independently reconciled semantic census,
source/observation correspondence and the full campaign/final verdict remain open.
