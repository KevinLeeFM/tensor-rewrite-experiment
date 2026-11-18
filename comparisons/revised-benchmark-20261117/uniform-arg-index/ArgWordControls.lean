import ArgWordProof
open RevisedBenchmark.ArgWord RevisedBenchmark.ArgReuse
set_option maxRecDepth 8192
example : reduce 8 128 .maximum finiteOne = (finiteOne, 0) := by decide
example : reduce 16 129 .minimum finiteOne = (finiteOne, 0) := by decide
example : ((reduce 8 129 .minimum finiteOne).2).toInt = -128 := by decide
example : step .maximum (finiteOne, (127 : BitVec 8)) (finiteOne,128) = (finiteOne,128) := by decide
