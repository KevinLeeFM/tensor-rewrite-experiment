# Frozen-v1 Dot/convolution source normalization

The companion JSON records all **75 exact frozen IDs**: 44 Dot and 31
convolution. It contains 39 ordered stages, 65 shared source contracts, 161
literal source excerpts with SHA256 hashes, and 75 independently checked
function byte-interval hashes. All 75 replacement/delegation anchors match the
frozen site-case map. All 16 earlier review artifacts remain unchanged.

The records comprise four shared API rows, 12 local caller aliases, one external
transformation call, and 58 action variants. These are lineage counts, not N/F.
The frozen suffixes for Dot's reorder-contracting and concat pairs denote the
**Constant side**; the transformed operand is on the other side. The overloaded
compatibility API has separate dispatch paths; its overload bodies are not
sequential stages.

Guards, ordered predecessor CONTINUATION, current captures and pointers,
construction and live writes, metadata, and API/status outcomes are recorded.
Dot mirror selection prefers the eligible left operand and never retries the
other side after a failed guard. Pad/Broadcast mirror cost vetoes can occur after
allocations and continue into later Dot stages. The nested batch-map role test
compares vector values. Broadcast axis deletion uses original contracting-axis
order without a local sortedness guard. These are source inspection findings;
the associated failure candidates were not executed in this review.

Outer-product Dot uses direct Multiply, whereas strength reduction calls the
virtual precision Multiply hook and widens floating accumulation to F32/F64.
Precision support checks the algorithm only; its has_contracting_dim argument is
unused. OptimizeDotOfGather actually recognizes DynamicSlice(Constant), and its
zero_start variable has no literal-zero guard.

Convolution scalar movement rewires operands/users before returning OK and
continuing through later caller stages. BF16 promotion returns false after
updating the caller's local pointer to a new F32 convolution; later simplifiers
operate on that new node. Compatible BF16 instead returns true without changing
the graph and stops the caller. Conv-to-Multiply has no local
conv-simplification flag or batch-group-one gate. Its BroadcastSequence callback
only inserts nodes; the ReduceWindow layout callback must not be substituted.

Every original ID is present. Local source programs are normalized under explicit
library/backend interfaces. The external SwapConvolutionOperandsIfBeneficial
implementation is absent and is not claimed inspected. Constructor semantics,
backend overrides, mathematical correctness and whole-pass reachability remain
declared boundaries, distinct from local source enumeration work.

No native runs, canonical edits, source/proof acceptance, or N/F freeze occurred.
Canonical alias/caller/effect reconciliation and proof/model closure remain
separate work.
