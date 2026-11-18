import ReorderSpec
import CopyProof
namespace RevisedBenchmark.CopyReshape
open CopyChain

private theorem through {n : Nat} {α : Type} (base prior dst : Dense n)
    (before : Bool) (mem : Fin n → α) :
    copy (if before then prior else base) dst (previous before base prior mem) =
      copy base dst mem := by
  cases before with
  | false => rfl
  | true => exact (CopyChain.verified _ _ _ base prior dst mem).1

theorem verified : Goal := by
  intro n α before skipCopy raw base prior shaped aligned final mem allowOmit allowRaw
  unfold old replacement
  rw [(CopyChain.verified _ _ _ _ shaped final _).1, through]
  have chosen : (if skipCopy then mem else
      copy (if before then prior else base) aligned (previous before base prior mem)) =
      copy base aligned mem := by
    cases skipCopy with
    | false => exact through base prior aligned before mem
    | true =>
      have equal := (allowOmit rfl).2
      subst aligned
      funext addr
      simp [copy, base.encode_decode]
  dsimp only
  rw [chosen]
  cases raw with
  | false => exact (CopyChain.verified _ _ _ base aligned final mem).1.symm
  | true =>
    funext addr
    change mem (base.address (final.coordinate addr)) = mem (base.address (aligned.coordinate addr))
    have e := allowRaw rfl (final.coordinate addr)
    rw [final.encode_decode] at e
    simpa [aligned.decode_encode] using congrArg (fun a => mem (base.address (aligned.coordinate a))) e
#print axioms verified
end RevisedBenchmark.CopyReshape
