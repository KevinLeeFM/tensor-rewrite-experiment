-- Run against the prior independent copy-reshape-chain-terminal module,
-- in a separate temporary search path.
import ChainProof
namespace CompressedChainBuffer
open RevisedBenchmark.DenseChain
theorem buffer_at_paired_addresses (n : Nat) (α : Type) (s t : LayoutN n)
    (data : Fin n → α) (h : ∀ i, s.address i = t.address i) :
    run s t [] data = data := raw_verified n α s t [] data h
#print axioms buffer_at_paired_addresses
end CompressedChainBuffer
