import TensorRewriteTheory
import FloatLib.Floats.Formats.BinaryInterchange.Configured.Type

open TensorRewrite.Theory.Convolution FloatLib.Floats

-- Rounded binary32 arithmetic is not given the semiring laws required by this exact model.
example (plan : Plan 0) (input : Input plan Binary32) (kernel : Kernel plan Binary32) :
    OutputIndex plan → Binary32 := convolve plan input kernel
