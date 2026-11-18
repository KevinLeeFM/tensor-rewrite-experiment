import U8Proof
namespace RevisedBenchmark.ConvU8
example : List.ofFn (conv xs (fun _ => 16)) = [240,255] := by decide
example : List.ofFn (product xs (fun _ => 16)) = [240,0] := by decide
example : convByte 255 1 = (255 : Byte) * 1 := by decide
example : convByte 7 73 = (7 : Byte) * 73 := by decide
example : convByte 255 255 = 255 ∧ (255 : Byte)*255 = 1 := by decide
end RevisedBenchmark.ConvU8
