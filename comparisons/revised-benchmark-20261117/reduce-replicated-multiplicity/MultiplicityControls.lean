import MultiplicityProof
set_option autoImplicit false
namespace RevisedBenchmark.ReduceMultiplicity
open ReduceMapped
example : IntCase := exactInt
example : ¬ FloatCase := refuted
example : emitted witness 0 0 = [1] := by decide
example : operandReads witness [3,1] = List.replicate 6 [1] := by decide
example : operandReads witness [3,0] = List.replicate 6 [0] := by decide
example : ((operandReads witness [3,1]).map values).foldl
    (fun a v => RadixIota.r32 (a+v)) 0 = 25165828 := by decide
example : RadixIota.r32 (RadixIota.r32 4194305 * RadixIota.r32 6) = 25165830 := by decide
example : RadixIota.r32 (6 * 1) =
    ((operandReads witness [3,0]).map values).foldl (fun a v => RadixIota.r32 (a+v)) 0 := by decide
example : operandReads [.reduced 0,.kept 2] [1] = [] := by decide
end RevisedBenchmark.ReduceMultiplicity
