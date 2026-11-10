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

#include <iostream>
#include <memory>
#include <string>

#include "absl/status/status.h"
#include "absl/status/status_matchers.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "xla/hlo/ir/hlo_computation.h"
#include "xla/hlo/ir/hlo_instruction.h"
#include "xla/hlo/ir/hlo_module.h"
#include "xla/hlo/parser/hlo_parser.h"
#include "xla/hlo/testlib/hlo_hardware_independent_test_base.h"
#include "xla/hlo/transforms/simplifiers/algebraic_simplifier.h"
#include "xla/service/hlo_verifier.h"

namespace xla {
namespace {

using ::absl_testing::StatusIs;
using ::testing::HasSubstr;

class EmptySliceBoundaryReplay : public HloHardwareIndependentTestBase {};

TEST_F(EmptySliceBoundaryReplay, EmptySliceProducesInvalidShape) {
  for (bool reversed : {false, true}) {
    SCOPED_TRACE(reversed);
    std::string hlo = R"hlo(
HloModule empty_slice_boundary
ENTRY main {
  operand = s32[4] parameter(0)
)hlo";
    if (reversed) {
      hlo += "  reversed = s32[4] reverse(operand), dimensions={0}\n";
    }
    hlo += std::string("  ROOT sliced = s32[0] slice(") +
           (reversed ? "reversed" : "operand") +
           "), slice={[1:1:2]}\n}\n";
    ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module,
                         ParseAndReturnUnverifiedModule(hlo));
    // Use a plain module: an invalid output is expected and explicitly checked;
    // VerifiedHloModule would report that same output again on destruction.
    HloVerifier input_verifier(/*layout_sensitive=*/false,
                               /*allow_mixed_precision=*/true);
    ASSERT_OK(input_verifier.Run(module.get()).status());
    const std::string before_hlo = module->ToString();
    AlgebraicSimplifierOptions options;
    options.set_run_to_fixed_point(false);
    AlgebraicSimplifier simplifier(options);
    ASSERT_OK_AND_ASSIGN(bool changed, simplifier.Run(module.get()));
    ASSERT_TRUE(changed);
    HloVerifier verifier(/*layout_sensitive=*/false,
                         /*allow_mixed_precision=*/true);
    const auto verified = verifier.Run(module.get());
    EXPECT_THAT(verified.status(),
                StatusIs(absl::StatusCode::kInternal, HasSubstr("shape")));
    std::cout << "EMPTY_SLICE_RESULT reversed=" << reversed
              << " original_verified=1 changed=1 rewritten_verified="
              << verified.ok() << "\nORIGINAL_HLO\n"
              << before_hlo << "REWRITTEN_HLO\n"
              << module->ToString() << "VERIFIER_STATUS\n"
              << verified.status() << "\n";
  }
}

TEST_F(EmptySliceBoundaryReplay, NonemptyStrideControlRemainsValid) {
  const char* hlo = R"hlo(
HloModule nonempty_slice_control
ENTRY main {
  operand = s32[4] parameter(0)
  ROOT sliced = s32[1] slice(operand), slice={[1:3:3]}
})hlo";
  ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module,
                       ParseAndReturnUnverifiedModule(hlo));
  HloVerifier input_verifier(/*layout_sensitive=*/false,
                             /*allow_mixed_precision=*/true);
  ASSERT_OK(input_verifier.Run(module.get()).status());
  AlgebraicSimplifierOptions options;
  options.set_run_to_fixed_point(false);
  AlgebraicSimplifier simplifier(options);
  ASSERT_OK_AND_ASSIGN(bool changed, simplifier.Run(module.get()));
  ASSERT_TRUE(changed);
  HloVerifier verifier(/*layout_sensitive=*/false,
                       /*allow_mixed_precision=*/true);
  ASSERT_OK(verifier.Run(module.get()).status());
  const HloInstruction* root = module->entry_computation()->root_instruction();
  EXPECT_EQ(root->slice_starts(0), 1);
  EXPECT_EQ(root->slice_limits(0), 2);
  EXPECT_EQ(root->slice_strides(0), 1);
  std::cout << "EMPTY_SLICE_CONTROL original_verified=1 changed=1"
               " rewritten_verified=1 start=1 limit=2 stride=1\n";
}

}  // namespace
}  // namespace xla
