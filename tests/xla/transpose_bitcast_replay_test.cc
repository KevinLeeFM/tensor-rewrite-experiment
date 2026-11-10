/* Copyright 2026 The OpenXLA Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
==============================================================================*/

#include <cstdint>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

#include "gtest/gtest.h"
#include "xla/hlo/evaluator/hlo_evaluator.h"
#include "xla/hlo/ir/hlo_module.h"
#include "xla/hlo/testlib/hlo_hardware_independent_test_base.h"
#include "xla/hlo/transforms/simplifiers/algebraic_simplifier.h"
#include "xla/literal.h"
#include "xla/literal_util.h"
#include "xla/service/hlo_verifier.h"
#include "xla/shape_util.h"

namespace xla {
namespace {
class TransposeBitcastReplay : public HloHardwareIndependentTestBase {};

TEST_F(TransposeBitcastReplay, DensePhysicalAddresses) {
  struct Case {
    const char* name;
    const char* input_shape;
    const char* output_shape;
    const char* permutation;
    bool sensitive;
    bool compatible;
    bool rank3;
  };
  const Case cases[] = {
      {"default_affine", "s32[2,3]{1,0}", "s32[3,2]{0,1}", "1,0", true, true, false},
      {"column_affine", "s32[2,3]{0,1}", "s32[3,2]{1,0}", "1,0", true, true, false},
      {"wrong_layout", "s32[2,3]{1,0}", "s32[3,2]{1,0}", "1,0", true, false, false},
      {"insensitive", "s32[2,3]{1,0}", "s32[3,2]{0,1}", "1,0", false, true, false},
      {"rank3_cycle", "s32[2,3,4]{2,1,0}", "s32[3,4,2]{1,0,2}", "1,2,0", true, true, true},
  };
  for (const Case& test : cases) {
    for (int mode : {0, 1, 2}) {
      SCOPED_TRACE(test.name);
      SCOPED_TRACE(mode);
      const std::string hlo = "HloModule transpose_bitcast\nENTRY main {\ndata = " +
          std::string(test.input_shape) + " parameter(0)\nROOT result = " + test.output_shape +
          " transpose(data), dimensions={" + test.permutation + "}\n}\n";
      ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module, ParseAndReturnVerifiedModule(hlo));
      HloInstruction* original_root = module->entry_computation()->root_instruction();
      EXPECT_EQ(ShapeUtil::TransposeIsBitcast(original_root->operand(0)->shape(),
          original_root->shape(), original_root->dimensions()), test.compatible);
      HloVerifier before_verifier(/*layout_sensitive=*/true, /*allow_mixed_precision=*/true);
      ASSERT_OK(before_verifier.Run(module.get()).status());
      const Shape& input_shape = module->entry_computation()->parameter_instruction(0)->shape();
      Literal data = test.rank3
          ? LiteralUtil::CreateR3<int32_t>({{{0,1,2,3},{10,11,12,13},{20,21,22,23}},
                                          {{100,101,102,103},{110,111,112,113},{120,121,122,123}}})
          : LiteralUtil::CreateR2<int32_t>({{0,1,2},{3,4,5}});
      data = data.Relayout(input_shape);
      std::vector<const Literal*> args{&data};
      HloEvaluator evaluator;
      ASSERT_OK_AND_ASSIGN(Literal before, evaluator.Evaluate(*module, args));
      const std::string original = module->ToString();
      bool changed = false;
      if (mode != 0) {
        AlgebraicSimplifierOptions options;
        options.set_is_layout_sensitive(test.sensitive);
        options.set_run_to_fixed_point(false);
        AlgebraicSimplifier simplifier(options);
        if (mode == 1) {
          AlgebraicSimplifierVisitor visitor(options, &simplifier);
          ASSERT_OK(visitor.HandleTranspose(module->entry_computation()->root_instruction()));
          changed = visitor.changed();
        } else {
          ASSERT_OK_AND_ASSIGN(changed, simplifier.Run(module.get()));
        }
      }
      const bool expected_changed = mode != 0 && test.sensitive && test.compatible;
      EXPECT_EQ(changed, expected_changed);
      EXPECT_EQ(module->entry_computation()->root_instruction()->opcode(),
                expected_changed ? HloOpcode::kBitcast : HloOpcode::kTranspose);
      if (mode == 0) EXPECT_EQ(module->ToString(), original);
      HloVerifier verifier(/*layout_sensitive=*/true, /*allow_mixed_precision=*/true);
      ASSERT_OK(verifier.Run(module.get()).status());
      HloEvaluator after_evaluator;
      ASSERT_OK_AND_ASSIGN(Literal after, after_evaluator.Evaluate(*module, args));
      int checked = 0;
      int selected = 0;
      if (test.rank3) {
        for (int b = 0; b < 3; ++b) for (int c = 0; c < 4; ++c) for (int a = 0; a < 2; ++a) {
          EXPECT_EQ(before.Get<int32_t>({b,c,a}), 100*a+10*b+c);
          EXPECT_EQ(after.Get<int32_t>({b,c,a}), 100*a+10*b+c);++checked;
        }
        selected = after.Get<int32_t>({0,0,1});
      } else {
        for (int col = 0; col < 3; ++col) for (int row = 0; row < 2; ++row) {
          EXPECT_EQ(before.Get<int32_t>({col,row}), 3*row+col);
          EXPECT_EQ(after.Get<int32_t>({col,row}), 3*row+col);++checked;
        }
        selected = after.Get<int32_t>({0,1});
      }
      std::cout << "TRANSPOSE_BITCAST_RESULT case=" << test.name
                << " mode=" << (mode == 0 ? "control" : mode == 1 ? "handler" : "pass")
                << " sensitive=" << test.sensitive << " compatible=" << test.compatible
                << " changed=" << changed << " checked=" << checked << " selected=" << selected
                << " rewritten_verified=1\nORIGINAL_HLO\n" << original
                << "REWRITTEN_HLO\n" << module->ToString();
    }
  }
}

TEST_F(TransposeBitcastReplay, TiledArraySizeBoundary) {
  const char* hlo = R"hlo(
HloModule tiled_transpose
ENTRY main {
 data = s32[2,3]{1,0:T(2,2)} parameter(0)
 ROOT result = s32[3,2]{0,1:T(4,4)} transpose(data), dimensions={1,0}
})hlo";
  ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module, ParseAndReturnVerifiedModule(hlo));
  HloInstruction* transpose = module->entry_computation()->root_instruction();
  const int64_t input_bytes = ShapeUtil::ArraySize(transpose->operand(0)->shape());
  const int64_t output_bytes = ShapeUtil::ArraySize(transpose->shape());
  EXPECT_EQ(input_bytes, 32);EXPECT_EQ(output_bytes, 64);
  EXPECT_TRUE(ShapeUtil::TransposeIsBitcast(transpose->operand(0)->shape(),
                                         transpose->shape(), transpose->dimensions()));
  const auto size = [](const Shape& shape) { return ShapeUtil::ArraySize(shape); };
  HloVerifier before_verifier(true, true, {}, size);
  ASSERT_OK(before_verifier.Run(module.get()).status());
  const std::string original = module->ToString();
  AlgebraicSimplifierOptions options;options.set_is_layout_sensitive(true);
  AlgebraicSimplifier simplifier(options);
  AlgebraicSimplifierVisitor visitor(options, &simplifier);
  ASSERT_OK(visitor.HandleTranspose(module->entry_computation()->root_instruction()));
  EXPECT_TRUE(visitor.changed());
  EXPECT_EQ(module->entry_computation()->root_instruction()->opcode(), HloOpcode::kBitcast);
  HloVerifier after_verifier(true, true, {}, size);
  auto verification = after_verifier.Run(module.get());
  EXPECT_FALSE(verification.ok());
  EXPECT_NE(verification.status().message().find("Bitcast cannot have different shape sizes"), std::string::npos);
  std::cout << "TILED_ARRAY_SIZE_RESULT input_bytes=" << input_bytes << " output_bytes=" << output_bytes
            << " compatible=1 changed=" << visitor.changed() << " original_verified=1 rewritten_verified="
            << verification.ok() << " operator_evaluation=0\nORIGINAL_HLO\n" << original
            << "REWRITTEN_HLO\n" << module->ToString()
            << "VERIFIER_DIAGNOSTIC\n" << verification.status() << "\n";
}
}  // namespace
}  // namespace xla
