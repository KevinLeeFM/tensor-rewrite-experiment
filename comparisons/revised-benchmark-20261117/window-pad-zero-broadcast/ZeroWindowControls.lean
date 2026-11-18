import ZeroWindowProof
namespace RevisedBenchmark.PadZ
example : broadcasted false true (fun _ => true) ⟨0,by decide⟩ = 0#32 := by decide
example : broadcasted false true (fun _ => true) ⟨1,by decide⟩ = 0x80000000#32 := by decide
example : old false true (fun _ => true) ⟨1,by decide⟩ 1 1 = 0#32 := by decide
example : old true false (fun _ => false) ⟨0,by decide⟩ 0 0 = broadcasted true false (fun _ => false) ⟨0,by decide⟩ := by decide
end RevisedBenchmark.PadZ
