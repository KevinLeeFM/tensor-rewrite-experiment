# Layout stages, copy chains and non-call graph writes

Source pin: e58e523b11f1fde802a493a776d158007486e1bf.
File: xla/hlo/transforms/simplifiers/algebraic_simplifier.cc.
Data: census/layout-cases.json; census/normalized-structural-sites.json;
census/review-ledger.json.

## Batch scope

The batch records 30 source branch/stage schemas: Bitcast6, BitcastConvert5,
Copy10, SwapCopyBitcastCopy2, TrySimplifyTautologicalBitcastConvert1, Constant4
and OptimizationBarrier2. All 21 lexical replacement sites within these selected
owners have bindings. Eight helper contracts have inspected source ranges and
body hashes, with their mathematical/layout guarantees still unproved.

At the initial layout checkpoint, five batches had 256 schema bindings, 201 distinct lexical
replacement sites bound and 143 replacement candidates unmapped. Neither these
counts nor branch/stage records are a frozen verification denominator. Complete
successful traces, status/error behavior, helper closure, types, layouts and
independent review still need reconciliation before source acceptance.

## Continuing control flow

HandleBitcast (:1548–1639) checks control dependencies on its initially visited
node. It may recursively simplify its inner bitcast, replace a composition,
rebind the local bitcast pointer, eliminate a compatible current node, rebind to
its operand and continue into chain/broadcast helpers. That current node can
have a different opcode from the initially visited Bitcast. Therefore a uniform
premise that earlier branches did not rewrite would misdescribe this handler.

The extraction labels these as branch/stage schemas, records continuations and
keeps the current local binding in its path conditions. Recursive delegation is
explicit. This is still an inspected control-flow description; it does not prove
termination, alias updates, helper applicability or all error-path invariants.

## Physical versus logical contracts

- Bitcast unary sandwich movement keeps element types equal and excludes tiling
  at the inspected input endpoints. Physical index preservation and cloned
  operator attributes require more than a logical reshape identity.
- BitcastConvert elimination depends on representation width, last-axis physical
  contiguity and element_size_in_bits, including sub-byte storage. Concatenated
  conversion cancellation must reconcile the concat axis before/after packing.
- Copy identity preserves a special entry-root sharding condition. Copy-to-
  bitcast conversion rejects a known memory-space transfer before invoking its
  layout-sensitive ancestor walk. The copy/reshape reordering path separately
  uses an equality that ignores memory space; this does not license ignoring
  memory space throughout the experiment.
- SwapCopyBitcastCopy rejects synchronous host transfers and inspects physical
  dimension maps, their inverse, tiling and virtual layout validity. The tiling
  helper explicitly returns true when either tile list is empty and otherwise
  examines the first tile with split/combine divisibility checks. These source
  predicates must be verified or carried as unresolved contracts, not replaced
  with a convenient abstract permutation witness.
- Copy/reshape reordering keeps the should_rewrite decision, allocation estimate
  and alternatives for omitting the new Copy and choosing Bitcast versus Reshape.
  Finite int64 size/product overflow remains separate from unbounded Lean Nat.
- Constant extraction retains tuple recursion and literal classification helpers
  for uniform, iota and strided-iota cases. Type, NaN-bit, finite-width and leaf
  behavior are dependencies rather than accepted identities.

## The barrier is a graph transformation

HandleOptimizationBarrier (:5575–5650) prunes unused tuple components only under
its user/token/effect conditions. A successful transformation mutates the
barrier's operand edge, assigns a new shape, remaps original-value metadata twice
and changes each GTE user's tuple index. MarkAsChanged occurs before subsequent
status-returning operations, which is relevant to error paths.

Both tuple-operand and general producer branches record the same five principal
effect anchors in source order. The shape assignment at :5642 is matched to a
real assignment-expression AST record; GTE setter and metadata anchors are also
retained. Output-only tensor equality would omit these user and metadata changes.
The five anchors are inspected evidence, not a claim that called metadata APIs
have been fully verified.

## Broader write discovery

The syntax inventory now retains assignment_expression nodes as well as the
959 previously discovered candidate calls. The normalized parse yields 436 such
expressions. Many are local pointer/counter/vector updates; 28 overlap syntax
normalization, whose ledger explains that macro status/return behavior is not
modeled. Assignment source text, target, value, operator, enclosing function,
conditional/loop context, byte coordinates and normalization provenance are
preserved. Pending assignment IDs also enter each handler review packet.

The new list cannot be read as 436 mutations to the HLO graph. Type/alias/path
analysis is required. Variable initializers and increment/decrement expressions
are not indexed as assignments; indirect method/helper writes and nonmatching
APIs can still escape the discovery vocabulary. A clean grammar parse does not
establish C++ type correctness, reachability or exhaustive graph-effect discovery.

## Checks and remaining work

Twenty-three Python tool/evidence tests pass. New controls remove a barrier user
effect or its actual shape-assignment record, omit an assignment, falsify its
target, fabricate acceptance or erase macro-normalization provenance. Each is
rejected. The context refactor preserves existing short-circuit/else/condition-
evaluation checks. The integrated checkpoint passes with all previous Lean and
archived XLA evidence. No new native pass run or Lean theorem is claimed here.

Lean size remains S148/H66/R172/A9/C106, total501. Source acceptance remains zero.
Compose continuing stages into source-faithful obligations, review aliased writes
and physical/helper contracts, and finish the remaining corpus before freezing N
or starting the scored whole-file campaign. The LLM/Lean verdict remains open.
