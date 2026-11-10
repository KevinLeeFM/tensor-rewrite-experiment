# Dense cell layouts and transpose-to-bitcast

Source: XLA e58e523b11f1fde802a493a776d158007486e1bf.
Contract: census/dense-layout-contract.json.
Source case: HandleTranspose/layout-bitcast, untiled dense same-cell-type subcase.
Complete source acceptance remains0.

## Source condition and modeled observations

ShapeUtil::TransposeIsBitcast (shape_util.cc:1734–1766) requires arrays with
layouts, matching element types unless explicitly ignored, and the exact array
equation ComposePermutations(transpose_dimensions,output_minor_to_major)=
input_minor_to_major. The handler uses the non-ignored element-type check.
The simplifier's wrapper (:300–330) adds checks for match-dimension tiles.
HandleTranspose uses this guard in layout-sensitive mode before replacing with
bitcast (:10584–10587), after its earlier branches fail.

DenseLayout stores a witnessed legal minor-to-major permutation. orderedShape
and toOrderedIndex reverse physical slots into the major-to-minor convention
used by the earlier mixed-radix linearization. fromOrderedIndex uses the inverse
permutation with derived extent casts. address is the resulting bounded cell
position. Row-major and column-major constructors make both conventions explicit.

Buffer, read and write provide an independent same-cell-type storage meaning.
bitcastTensor reinterprets one encoded buffer through an output shape/layout,
with equal physical cell counts explicit. This semantics covers arbitrary finite
rank, natural extents, scalars and empty arrays. It does not model tiled/padded
addresses, packed sub-byte cells, dtype-changing bitcast-convert, memory spaces
or raw bytes.

## General proofs

The two coordinate reorderings are inverse, and read/write are inverse for all
valid logical coordinates and physical cell positions. No output-to-input map,
address-equality conclusion or positive-extent restriction is supplied by callers.

MinorOrderMatches states the actual source array equation. Two support theorems
relate it to its component-wise axis equality. From it and the legal transpose
extent relation, the proof derives equality of physically ordered shapes and
addresses. transpose_eq_bitcast then proves equality of logical transpose and
same-cell bitcast for every input tensor in this profile, parametric in element
type. Equality of physical counts is derived from the shapes, not assumed as an
extra restriction on the transpose rule.

Concrete guard proofs use the component theorem and kernel-checked finite-axis
facts. A separate executable decision instance checks the finite array equation
in probes. Compiled evaluation is diagnostic evidence; no native_decide or
unchecked evaluation discharges the general theorem or its concrete guard proofs.

Four older permutation/index files needed Lean module/public exposure before
the new modules could import them. Their mathematical definitions/statements
were retained, and every earlier theorem axiom set is unchanged.

## Native dense cases and wrong-guard controls

reports/transpose-bitcast-replay-v2 archives two native tests. The dense test
uses five profiles, each with no rewrite, direct HandleTranspose and one full
pass. Original and rewritten modules pass layout-sensitive verification.
Every output coordinate is checked directly, with nonuniform s32 labels.

| Profile | Guard | Layout-sensitive option | Handler/pass outcome |
| --- | --- | --- | --- |
| [2,3]{1,0}→[3,2]{0,1}, swap | true | true | Bitcast; all6 values preserved |
| [2,3]{0,1}→[3,2]{1,0}, swap | true | true | Bitcast; all6 values preserved |
| [2,3]{1,0}→[3,2]{1,0}, swap | false | true | Transpose retained |
| First affine profile | true | false | Transpose retained |
| [2,3,4]{2,1,0}→[3,4,2]{1,0,2}, cycle1,2,0 | true | true | Bitcast; all24 values preserved |

All five no-rewrite controls preserve their HLO. These parameter-input,
nonidentity permutations do not match the earlier identity/nested/degenerate
transpose paths; the single transpose's effective permutation is nonidentity,
so the earlier identity-chain helper also does not remove it.

Lean probes compute the correct swapped sequence0,3,1,4,2,5 and the wrong-layout
bitcast sequence0,1,2,3,4,5. Their difference witnesses why the array guard cannot
be dropped. The rank3 probe selects value100 at physical cell12; native execution
selects the same value and checks the complete tensor. The native test compares
values, not a direct implementation-to-Lean address extraction proof.

## Separate tiled ArraySize verifier boundary

The tiled test uses input s32[2,3]{1,0:T(2,2)} and output
s32[3,2]{0,1:T(4,4)} with swap1,0. ShapeUtil::ArraySize reports32 input bytes and
64 output bytes. The minor-order guard accepts, and the real direct handler
produces a Bitcast. The positive tile sizes contain no kMatchDimension, so the
simplifier wrapper's additional match-dimension check does not reject them.

The original Transpose verifies with HloVerifier configured layout-sensitive,
shape_size=ShapeUtil::ArraySize and the default prohibition of different bitcast
sizes. The rewritten Bitcast is rejected specifically for unequal shape sizes.
The source verifier accepts a target-specific size function; its constructor,
default policy and the exact fixture are preserved. This is a reproducible
verifier-relative well-formedness failure under that policy.

The test invokes only the direct handler for this tiled diagnostic and does not
evaluate tiled tensor values. It does not establish adoption of that size policy
by a particular backend or prove tiled value semantics in Lean. Do not merge it
with the dense proof, count it as a new Lean refutation, or assert a production
backend failure. It identifies a concrete remaining source/profile obligation.

The first native archive retained a failed fixture build because two SCOPED_TRACE
macros shared one source line. V2 fixes that infrastructure error and passes.
Reproduce with tools/run_transpose_bitcast_replay.py and a new archive basename.
The accepted archive preserves fixture, BUILD, uncached test command/events,
logs/XML, source identity and binary hash.

## Validation and code burden

The checker verifies source ranges/header hashes, precise model/native scopes,
all15 dense observations and the tiled diagnostic. Controls reject promotion to
tiled/packed semantics, mislabeling the tiled result a Lean refutation, claiming
tiled evaluation, or changing the wrong-layout guard to true. A false proof of
unconditional minor-order compatibility must fail. All46 tool/evidence tests and
the integrated checkpoint pass, including the typed census checks.

| Lean category | Previous | Current | Added |
| --- | ---: | ---: | ---: |
| S semantics | 482 | 550 | 68 |
| H support | 528 | 631 | 103 |
| R rule proofs | 364 | 395 | 31 |
| A imports/checking | 21 | 22 | 1 |
| C certificates | 177 | 177 | 0 |
| Total | 1572 | 1775 | 203 |

Eight added lines expose the four legacy modules; the other195 cover new layout
semantics, proofs and import. All are counted. Test/audit code is reported
separately in reports/pilot-values.json. The development now has48 value rules
and60 support theorems; these overlap source cases and are not coverage fractions.

snapshots/dense-layout-pilot-v1.zip preserves the complete Lean development.
reports/dense-layout-clean-replay.json records fresh replay without build caches,
matching code size, axiom dependencies and model probes. This is same-agent Lean
replay, not independent source review or native rebuilding.

Remaining work includes signed attribute extraction, finite byte/storage formats,
tiles/padding/packing, memory spaces, backend policy adoption and graph/API/frame
correspondence. Independent census/pilot review, the full campaign and final
research verdict remain open.
