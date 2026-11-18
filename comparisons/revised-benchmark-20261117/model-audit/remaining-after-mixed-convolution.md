# Remaining source labels after the mixed-convolution continuation

The ledger links 466 of 488 source labels to reviewed cases or inherited mathematical evidence. The 22 labels below are the exact set without such a link. None is counted as a new mathematical case. This list does not imply complete domain coverage for the linked labels.

## Nested dot with transposed output

Attempted overlap; missing typed output reindexing. Construct the source permutation P from old to new result axes, exhibit nonidentity P with an admitted profitable plan, and check the original and reassociated reads at q and inverse-mapped q. Existing direct matrix counterexamples use identity P.

`AssociativeReorderNestedDot/lhs-transpose` (line 4272) · `AssociativeReorderNestedDot/rhs-transpose` (line 4272). [Inspection](dot-swap-tail.md)

## Variable reshape/transpose/bitcast chain

Attempted proof reuse; intermediate permutation acts at a changing rank. Prove the deletion-of-one-unit coordinate diagram and compose it through the selected sequence. Two individually unsorted transposes can cancel across a reshape. Single-step sortedness and pure-copy fusion both miss that case. Only then specialize physical equality, bitcasting or logical forwarding.

`HandleBitcast/chain-delegation` (line 1615) · `HandleReshape/transpose-chain-delegation` (line 6954) · `HandleTranspose/chain-delegation` (line 10433) · `TryRemovingBitcastOrReshapeTransposeChain/layout-bitcast` (line 6844) · `TryRemovingBitcastOrReshapeTransposeChain/layout-identity` (line 6834) · `TryRemovingBitcastOrReshapeTransposeChain/logical-identity` (line 6852). [Inspection](terminal-chain-scope.md)

## Contiguous-chunk hoist

Attempted overlap; a distinct block-ordering theorem is required. Relate output digits unflattened inside each source interval to input offsets after sorting the intervals and transposing the resulting block axes. Exercise [24] → [2,3,4] → [4,2,3] → [4,6] versus [6,4] → [4,6]. The accepted space-depth graph produces a concatenation.

`TryHoistTransposeOfReshape/contiguous-chunks` (line 6905) · `HandleReshape/transpose-hoist-delegation` (line 6963). [Inspection](terminal-chain-scope.md)

## Recursive graph mutation

Call site without an unconditional value-level replacement. Specify the successful inner mutation or preserved operand and re-match the outer graph before applying a terminal theorem. Crediting every inner case here would duplicate case identities.

`HandleBitcast/recursive-inner` (line 1592). [Inspection](dense-tail-reuse-review.md)

## LayoutConstraint custom call

Missing independently established source-target value contract. The retained simplifier tests check the replacement opcode and shape. Establish what the LayoutConstraint target returns for equal or changed layouts independently of the proposed rewrite. A generic opaque custom call may compute any value; assuming transparency would decide the question in advance.

`HandleCustomCall/layout-copy` (line 6131) · `HandleCustomCall/layout-identity` (line 6129). [Inspection](audit137-reuse-review.md)

## Tuple start operand

No admitted tuple-start DUS in the pinned shape verifier. DUS shape inference inspects index operand shapes without unpacking tuples. Each legal encoding requires scalar integers or a single integral vector. Record an inapplicable lexical path; a vacuous value theorem would add no benchmark result.

`HandleDynamicUpdateSlice/pad-tuple` (line 8539). [Inspection](dus-index-container-scope.md)

## Positive-real log/sqrt

Historical positive-real theorem has the opposite multiplication order. Replay pointwise commutation of the exact factor 1/2 with log(x) using the pinned real library. The archived positive-real result and its extent do not settle other domains. The cloud lacks the pinned Mathlib cache, and its endpoint was not retried.

`HandleLog/sqrt` (line 5542). [Inspection](numerical-tail-reuse-review.md)

## Named monotonicity through maximum

A generic monotone-function maximum theorem does not certify any of the three functions. Bind each named function to its exact definition/domain and an independently checked monotonicity result. A claim about its machine evaluator would separately require a numerical profile. No named-function proof was found in the inspected retained closure.

`HandleMaximum/sink-erf` (line 5024) · `HandleMaximum/sink-logistic` (line 5024) · `HandleMaximum/sink-tanh` (line 5024). [Inspection](numerical-tail-reuse-review.md)

## Generic replacement plumbing

Graph operation with no unique original/replacement value pair. Choose the caller, old expression, replacement operand(s), and observation. Shape compatibility or equal byte size alone cannot prove value equality. Many callers already have checked mathematical cases.

`ReplaceInstructionIfCompatible/single` (line 876) · `ReplaceInstructionIfCompatible/span-single` (line 896) · `ReplaceInstructionIfCompatible/span-tuple` (line 910) · `ReplaceWithBitcast/unary` (line 855). [Inspection](audit137-reuse-review.md)

The first proposed structural gate is a single commuting diagram for deleting a unit coordinate in a transpose. The source review estimates 10–20 minutes for that prerequisite, with chain induction, endpoint integration and independent review still to follow. No general proof-development time or cost for those later phases is known. The other remaining mathematical clusters need different semantics or proofs.
