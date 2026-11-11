import TensorRewrite.Comparisons.FixedTacticsGuard
import TensorRewriteTheory

def wrongStatement : Prop := False

run_cmd do
  TensorRewrite.Comparisons.FixedTactics.sameStatement
    `TensorRewrite.Theory.FloatNegation.scalar_involution `wrongStatement
