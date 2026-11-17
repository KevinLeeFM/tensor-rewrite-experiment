module
import Guard
import Spec
private theorem wrongSignature : True := trivial
run_cmd Heldout.TransposeBroadcastGuard.exactGoal ``wrongSignature ``Heldout.TransposeBroadcast.Goal
