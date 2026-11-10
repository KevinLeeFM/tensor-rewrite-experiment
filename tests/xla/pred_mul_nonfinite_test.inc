// Diagnostic snippet for the pinned algebraic_simplifier_test.cc fixture.
// Requires HloEvaluator, <cmath>, <limits>, and <vector> includes/dependencies.
// Not compiled or run in this workspace; see reports/pred-mul-analysis.md.
TEST_F(AlgebraicSimplifierTest, PredMulNonfiniteStrictIEEEWitness) {
  constexpr char hlo[] = R"(
HloModule pred_mul_nonfinite
ENTRY main {
  predicate = pred[] parameter(0)
  operand = f32[] parameter(1)
  converted = f32[] convert(predicate)
  ROOT product = f32[] multiply(converted, operand)
})";
  TF_ASSERT_OK_AND_ASSIGN(auto module, ParseAndReturnVerifiedModule(hlo));
  Literal predicate = LiteralUtil::CreateR0<bool>(false);
  Literal operand = LiteralUtil::CreateR0<float>(
      std::numeric_limits<float>::infinity());
  std::vector<const Literal*> args{&predicate, &operand};
  HloEvaluator before_evaluator;
  TF_ASSERT_OK_AND_ASSIGN(auto before, before_evaluator.Evaluate(*module, args));
  AlgebraicSimplifierOptions options = default_options_;
  options.set_enable_fast_math(false);
  options.set_run_to_fixed_point(false);
  AlgebraicSimplifier simplifier(options);
  TF_ASSERT_OK_AND_ASSIGN(bool changed, simplifier.Run(module.get()));
  ASSERT_TRUE(changed);
  EXPECT_EQ(module->entry_computation()->root_instruction()->opcode(),
            HloOpcode::kSelect);
  HloEvaluator after_evaluator;
  TF_ASSERT_OK_AND_ASSIGN(auto after, after_evaluator.Evaluate(*module, args));
  EXPECT_TRUE(std::isnan(before.GetFirstElement<float>()));
  EXPECT_EQ(after.GetFirstElement<float>(), 0.0f);
}
