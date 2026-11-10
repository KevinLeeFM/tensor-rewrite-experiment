#include <cmath>
#include <iostream>
#include <limits>
#include <memory>
#include <string>
#include <vector>

#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "xla/hlo/evaluator/hlo_evaluator.h"
#include "xla/hlo/ir/hlo_computation.h"
#include "xla/hlo/ir/hlo_instruction.h"
#include "xla/hlo/ir/hlo_module.h"
#include "xla/hlo/ir/hlo_opcode.h"
#include "xla/hlo/testlib/hlo_hardware_independent_test_base.h"
#include "xla/hlo/transforms/simplifiers/algebraic_simplifier.h"
#include "xla/literal.h"
#include "xla/literal_util.h"

namespace xla {
namespace {

class PredMulNonfiniteReplay : public HloHardwareIndependentTestBase {};

TEST_F(PredMulNonfiniteReplay, StrictIEEEWitness) {
  struct Witness {
    const char* name;
    float value;
  };
  const Witness witnesses[] = {
      {"positive_infinity", std::numeric_limits<float>::infinity()},
      {"negative_infinity", -std::numeric_limits<float>::infinity()},
      {"quiet_nan", std::numeric_limits<float>::quiet_NaN()},
  };
  for (bool swapped : {false, true}) {
    for (const Witness& witness : witnesses) {
      SCOPED_TRACE(witness.name);
      SCOPED_TRACE(swapped);
      std::string hlo = R"hlo(
HloModule pred_mul_nonfinite
ENTRY main {
  predicate = pred[] parameter(0)
  operand = f32[] parameter(1)
  converted = f32[] convert(predicate)
  ROOT product = f32[] multiply(converted, operand)
})hlo";
      if (swapped) {
        const std::string pattern = "multiply(converted, operand)";
        const size_t position = hlo.find(pattern);
        ASSERT_NE(position, std::string::npos);
        hlo.replace(position, pattern.size(), "multiply(operand, converted)");
      }
      ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module,
                           ParseAndReturnVerifiedModule(hlo));
      const std::string before_hlo = module->ToString();
      Literal predicate = LiteralUtil::CreateR0<bool>(false);
      Literal operand = LiteralUtil::CreateR0<float>(witness.value);
      std::vector<const Literal*> args{&predicate, &operand};
      HloEvaluator before_evaluator;
      ASSERT_OK_AND_ASSIGN(Literal before,
                           before_evaluator.Evaluate(*module, args));
      AlgebraicSimplifierOptions options;
      options.set_enable_fast_math(false);
      options.set_run_to_fixed_point(false);
      AlgebraicSimplifier simplifier(options);
      ASSERT_OK_AND_ASSIGN(bool changed, simplifier.Run(module.get()));
      ASSERT_TRUE(changed);
      ASSERT_EQ(module->entry_computation()->root_instruction()->opcode(),
                HloOpcode::kSelect);
      HloEvaluator after_evaluator;
      ASSERT_OK_AND_ASSIGN(Literal after,
                           after_evaluator.Evaluate(*module, args));
      ASSERT_TRUE(std::isnan(before.GetFirstElement<float>()));
      ASSERT_EQ(after.GetFirstElement<float>(), 0.0f);
      std::cout << "PRED_MUL_RESULT input=" << witness.name
                << " swapped=" << swapped << " before_nan=1 after_zero=1\n"
                << "ORIGINAL_HLO\n"
                << before_hlo << "REWRITTEN_HLO\n"
                << module->ToString();
    }
  }
}

}  // namespace
}  // namespace xla
