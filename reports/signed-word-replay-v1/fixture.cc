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
#include <bit>
#include <type_traits>
#include <limits>
#include <functional>
#include <sstream>
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

namespace xla {
namespace {
class SignedWordReplay : public HloHardwareIndependentTestBase {};

template <typename T>
void CheckSignedType(const std::string& dtype,
    const std::function<absl::StatusOr<std::unique_ptr<HloModule>>(const std::string&)>& parse) {
  using Unsigned = std::make_unsigned_t<T>;
  static_assert(std::is_signed_v<T>);
  static_assert(std::bit_cast<T>(std::numeric_limits<Unsigned>::max()) == T(-1));
  const uint64_t maximum = std::numeric_limits<Unsigned>::max();
  const uint64_t high = maximum/2+1;
  const auto from_bits = [](uint64_t value) {return std::bit_cast<T>(static_cast<Unsigned>(value));};
  const std::vector<T> av{from_bits(high-1),from_bits(high),from_bits(maximum),from_bits(high+1),from_bits(high-2),from_bits(0)};
  const std::vector<T> bv{from_bits(1),from_bits(maximum),from_bits(2),from_bits(high-1),from_bits(3),from_bits(high)};
  const std::vector<T> cv{from_bits(maximum),from_bits(2),from_bits(3),from_bits(high),from_bits(high-1),from_bits(1)};
  for (const std::string name : {"add_zero","add_constant","add_assoc","factor",
                                "mul_zero","mul_one","mul_neg_neg","four_factors"}) {
    for (const std::string mode : {"control","handler","pass"}) {
      SCOPED_TRACE(dtype);
      SCOPED_TRACE(name);
      SCOPED_TRACE(mode);
      const std::string shape = dtype+"[6]";
      const auto node = [&](const std::string& n,const std::string& rhs) {
        return n+" = "+shape+" "+rhs+"\n";
      };
      std::string expression;
      bool add = true;
      if (name == "add_zero") expression = node("zero","constant({0,0,0,0,0,0})")+node("ROOT result","add(data,zero)");
      if (name == "add_constant") expression = node("c2","constant({2,2,2,2,2,2})")+node("ROOT result","add(c2,data)");
      if (name == "add_assoc") expression = node("c1","constant({2,2,2,2,2,2})")+node("c2","constant({3,3,3,3,3,3})")+node("inner","add(data,c1)")+node("ROOT result","add(inner,c2)");
      if (name == "factor") expression = node("left","multiply(data,shared)")+node("right","multiply(other,shared)")+node("ROOT result","add(left,right)");
      if (name == "mul_zero") expression = node("zero","constant({0,0,0,0,0,0})")+node("ROOT result","multiply(data,zero)");
      if (name == "mul_one") expression = node("one","constant({1,1,1,1,1,1})")+node("ROOT result","multiply(data,one)");
      if (name == "mul_neg_neg") expression = node("left","negate(data)")+node("right","negate(other)")+node("ROOT result","multiply(left,right)");
      if (name == "four_factors") expression = node("c1","constant({2,2,2,2,2,2})")+node("c2","constant({3,3,3,3,3,3})")+node("left","multiply(data,c1)")+node("right","multiply(other,c2)")+node("ROOT result","multiply(left,right)");
      if (name.starts_with("mul_") || name == "four_factors") add = false;
      const std::string hlo = "HloModule modular\nENTRY main {\n"+node("data","parameter(0)")+node("other","parameter(1)")+node("shared","parameter(2)")+expression+"}\n";
      ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module,parse(hlo));
      Literal a = LiteralUtil::CreateR1<T>(av);
      Literal b = LiteralUtil::CreateR1<T>(bv);
      Literal c = LiteralUtil::CreateR1<T>(cv);
      std::vector<const Literal*> args{&a,&b,&c};
      HloEvaluator before_evaluator;
      ASSERT_OK_AND_ASSIGN(Literal before,before_evaluator.Evaluate(*module,args));
      const std::string original = module->ToString();
      bool changed = false;
      if (mode != "control") {
        AlgebraicSimplifierOptions options;options.set_run_to_fixed_point(false);
        AlgebraicSimplifier simplifier(options);
        if (mode == "handler") {
          AlgebraicSimplifierVisitor visitor(options,&simplifier);
          HloInstruction* root = module->entry_computation()->root_instruction();
          if (add) {ASSERT_OK(visitor.HandleAdd(root));}
          else {ASSERT_OK(visitor.HandleMultiply(root));}
          changed = visitor.changed();
        } else {ASSERT_OK_AND_ASSIGN(changed,simplifier.Run(module.get()));}
      }
      EXPECT_EQ(changed,mode != "control");
      HloVerifier verifier(false,true);
      ASSERT_OK(verifier.Run(module.get()).status());
      HloEvaluator after_evaluator;
      ASSERT_OK_AND_ASSIGN(Literal after,after_evaluator.Evaluate(*module,args));
      std::ostringstream values,signed_values;
      for (int i = 0; i < 6; ++i) {
        const uint64_t x = std::bit_cast<Unsigned>(av[i]),y = std::bit_cast<Unsigned>(bv[i]),z = std::bit_cast<Unsigned>(cv[i]);
        uint64_t expected = x;
        if (name == "add_constant") expected = x+2;
        if (name == "add_assoc") expected = x+5;
        if (name == "factor") expected = (x+y)*z;
        if (name == "mul_zero") expected = 0;
        if (name == "mul_neg_neg") expected = x*y;
        if (name == "four_factors") expected = (x*y)*6;
        expected &= maximum;
        EXPECT_EQ(static_cast<uint64_t>(std::bit_cast<Unsigned>(before.Get<T>({i}))),expected);
        EXPECT_EQ(static_cast<uint64_t>(std::bit_cast<Unsigned>(after.Get<T>({i}))),expected);
        if (i) {values << ",";signed_values << ",";}
        signed_values << static_cast<int64_t>(after.Get<T>({i}));
        values << static_cast<uint64_t>(std::bit_cast<Unsigned>(after.Get<T>({i})));
      }
      std::cout << "SIGNED_WORD_RESULT dtype=" << dtype << " case=" << name << " mode=" << mode
                << " changed=" << changed << " checked=6 values=" << values.str()
                << " signed=" << signed_values.str() << " rewritten_verified=1\nORIGINAL_HLO\n" << original
                << "REWRITTEN_HLO\n" << module->ToString();
    }
  }
}

TEST_F(SignedWordReplay, SignedOverflowAndNarrowing) {
  std::cout << std::unitbuf;
  const auto parse = [this](const std::string& hlo) {return ParseAndReturnVerifiedModule(hlo);};
  CheckSignedType<int8_t>("s8",parse);
  CheckSignedType<int16_t>("s16",parse);
  CheckSignedType<int32_t>("s32",parse);
  CheckSignedType<int64_t>("s64",parse);
}
}  // namespace
}  // namespace xla
