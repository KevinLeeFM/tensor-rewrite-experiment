module
import Guard
import Spec
private theorem wrongSignature : True := trivial
run_cmd Heldout.DynamicTransposeGuard.exactGoal ``wrongSignature ``Heldout.DynamicTranspose.Goal
