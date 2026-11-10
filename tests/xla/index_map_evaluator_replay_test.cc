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
#include <vector>

#include "gtest/gtest.h"
#include "xla/hlo/evaluator/hlo_evaluator.h"
#include "xla/hlo/ir/hlo_module.h"
#include "xla/hlo/testlib/hlo_hardware_independent_test_base.h"
#include "xla/literal.h"
#include "xla/literal_util.h"

namespace xla {
namespace {

class IndexMapEvaluatorReplay : public HloHardwareIndependentTestBase {};

TEST_F(IndexMapEvaluatorReplay, BroadcastProjection) {
  const char* hlo = R"hlo(
HloModule broadcast_coordinates
ENTRY main {
  operand = s32[2,3] parameter(0)
  ROOT result = s32[2,4,3] broadcast(operand), dimensions={0,2}
})hlo";
  ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module,
                       ParseAndReturnVerifiedModule(hlo));
  Literal operand = LiteralUtil::CreateR2<int32_t>({{0, 1, 2}, {3, 4, 5}});
  std::vector<const Literal*> args{&operand};
  HloEvaluator evaluator;
  ASSERT_OK_AND_ASSIGN(Literal output, evaluator.Evaluate(*module, args));
  for (int64_t row = 0; row < 2; ++row) {
    for (int64_t middle = 0; middle < 4; ++middle) {
      for (int64_t col = 0; col < 3; ++col) {
        EXPECT_EQ(output.Get<int32_t>({row, middle, col}),
                  operand.Get<int32_t>({row, col}));
      }
    }
  }
  std::cout << "INDEX_MAP_BROADCAST axes=0,2 checked=24 selected="
            << output.Get<int32_t>({1, 3, 2}) << "\n";
}

TEST_F(IndexMapEvaluatorReplay, NonuniformStaticSlice) {
  const char* hlo = R"hlo(
HloModule slice_coordinates
ENTRY main {
  operand = s32[6,7] parameter(0)
  ROOT result = s32[3,2] slice(operand), slice={[1:6:2],[2:7:3]}
})hlo";
  ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module,
                       ParseAndReturnVerifiedModule(hlo));
  Literal operand = LiteralUtil::CreateR2<int32_t>(
      {{0, 1, 2, 3, 4, 5, 6}, {7, 8, 9, 10, 11, 12, 13},
       {14, 15, 16, 17, 18, 19, 20}, {21, 22, 23, 24, 25, 26, 27},
       {28, 29, 30, 31, 32, 33, 34}, {35, 36, 37, 38, 39, 40, 41}});
  std::vector<const Literal*> args{&operand};
  HloEvaluator evaluator;
  ASSERT_OK_AND_ASSIGN(Literal output, evaluator.Evaluate(*module, args));
  const int32_t expected[] = {9, 12, 23, 26, 37, 40};
  for (int64_t row = 0; row < 3; ++row) {
    for (int64_t col = 0; col < 2; ++col) {
      EXPECT_EQ(output.Get<int32_t>({row, col}), expected[row * 2 + col]);
    }
  }
  std::cout << "INDEX_MAP_SLICE checked=6 values=";
  for (int64_t row = 0; row < 3; ++row) {
    for (int64_t col = 0; col < 2; ++col) {
      if (row != 0 || col != 0) {
        std::cout << ",";
      }
      std::cout << output.Get<int32_t>({row, col});
    }
  }
  std::cout << "\n";
}

TEST_F(IndexMapEvaluatorReplay, EmptyStaticSlice) {
  const char* hlo = R"hlo(
HloModule empty_slice_coordinates
ENTRY main {
  operand = s32[4] parameter(0)
  ROOT result = s32[0] slice(operand), slice={[1:1:2]}
})hlo";
  ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module,
                       ParseAndReturnVerifiedModule(hlo));
  Literal operand = LiteralUtil::CreateR1<int32_t>({0, 1, 2, 3});
  std::vector<const Literal*> args{&operand};
  HloEvaluator evaluator;
  ASSERT_OK_AND_ASSIGN(Literal output, evaluator.Evaluate(*module, args));
  EXPECT_EQ(output.element_count(), 0);
  std::cout << "INDEX_MAP_EMPTY elements=" << output.element_count() << "\n";
}

TEST_F(IndexMapEvaluatorReplay, StrideLargerThanInterval) {
  const char* hlo = R"hlo(
HloModule large_stride_coordinates
ENTRY main {
  operand = s32[4] parameter(0)
  ROOT result = s32[1] slice(operand), slice={[1:3:5]}
})hlo";
  ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module,
                       ParseAndReturnVerifiedModule(hlo));
  Literal operand = LiteralUtil::CreateR1<int32_t>({0, 1, 2, 3});
  std::vector<const Literal*> args{&operand};
  HloEvaluator evaluator;
  ASSERT_OK_AND_ASSIGN(Literal output, evaluator.Evaluate(*module, args));
  EXPECT_EQ(output.Get<int32_t>({0}), 1);
  std::cout << "INDEX_MAP_LARGE_STRIDE value=" << output.Get<int32_t>({0}) << "\n";
}

}  // namespace
}  // namespace xla
