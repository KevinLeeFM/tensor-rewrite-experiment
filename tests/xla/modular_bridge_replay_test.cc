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
class ModularBridgeReplay : public HloHardwareIndependentTestBase {};

struct Recipe {std::string name;std::string family;int left;int right;int outer;int axis;};

std::vector<Recipe> Recipes() {
  std::vector<Recipe> cases;
  for (int left : {0,1}) for (int right : {0,1})
    cases.push_back({"factor_"+std::to_string(left)+std::to_string(right),"factor",left,right,0,0});
  for (int inner : {0,1}) for (int outer : {0,1})
    cases.push_back({"product_"+std::to_string(inner)+std::to_string(outer),"product",inner,0,outer,0});
  for (int left : {0,1}) for (int right : {0,1}) for (int outer : {0,1})
    cases.push_back({"four_"+std::to_string(left)+std::to_string(right)+std::to_string(outer),"four",left,right,outer,0});
  for (int axis : {0,1}) for (int inner : {0,1}) for (int outer : {0,1})
    cases.push_back({"move_"+std::to_string(axis)+"_"+std::to_string(inner)+std::to_string(outer),"move",inner,0,outer,axis});
  for (const std::string name : {"add_broadcast","subadd_broadcast","mul_broadcast","guard_vector_constant","guard_nonbroadcast"})
    cases.push_back({name,name,0,0,0,0});
  return cases;
}

std::string Mul(const std::string& left,const std::string& right,int swapped) {
  return "multiply("+(swapped ? right : left)+","+(swapped ? left : right)+")";
}

template <typename T>
void CheckBridgeType(const std::string& dtype,
    const std::function<absl::StatusOr<std::unique_ptr<HloModule>>(const std::string&)>& parse) {
  const uint64_t maximum = std::numeric_limits<T>::max();
  const uint64_t high = maximum/2+1;
  for (const Recipe& recipe : Recipes()) for (const std::string mode : {"control","handler","pass"}) {
    SCOPED_TRACE(dtype);
    SCOPED_TRACE(recipe.name);
    SCOPED_TRACE(mode);
    const std::string shape = dtype+"[2,2]";
    const auto node = [&](const std::string& name,const std::string& rhs) {return name+" = "+shape+" "+rhs+"\n";};
    std::string expression;
    const std::string family = recipe.family;
    if (family == "factor") expression = node("left",Mul("data","shared",recipe.left))+node("right",Mul("other","shared",recipe.right))+node("ROOT result","add(left,right)");
    if (family == "product" || family == "four") {
      expression = node("c1","constant({{2,2},{2,2}})")+node("c2","constant({{3,3},{3,3}})");
      expression += node("left",Mul("data","c1",recipe.left));
      if (family == "product") expression += node("ROOT result",Mul("left","c2",recipe.outer));
      else expression += node("right",Mul("other","c2",recipe.right))+node("ROOT result",Mul("left","right",recipe.outer));
    }
    if (family == "move" || family.starts_with("guard_")) {
      if (family == "guard_vector_constant") expression = node("scale","constant({{2,3},{4,5}})");
      else expression = "scalar = "+dtype+"[] constant(2)\n"+node("scale","broadcast(scalar), dimensions={}");
      expression += node("left",Mul("data","scale",recipe.left));
      if (family == "guard_nonbroadcast") expression += node("ROOT result",Mul("left","other",recipe.outer));
      else expression += node("broadcasted","broadcast(small), dimensions={"+std::to_string(recipe.axis)+"}")+node("ROOT result",Mul("left","broadcasted",recipe.outer));
    }
    if (family.ends_with("_broadcast")) {
      expression = "constant_first = "+dtype+"[] constant(2)\nconstant_second = "+dtype+"[] constant(3)\n"+node("c1","broadcast(constant_first), dimensions={}")+node("c2","broadcast(constant_second), dimensions={}");
      if (family == "add_broadcast") expression += node("left","add(data,c1)")+node("ROOT result","add(left,c2)");
      if (family == "subadd_broadcast") expression += node("left","subtract(c1,data)")+node("ROOT result","add(left,c2)");
      if (family == "mul_broadcast") expression += node("left","multiply(data,c1)")+node("ROOT result","multiply(left,c2)");
    }
    const std::string hlo = "HloModule modular_bridge\nENTRY main {\n"+node("data","parameter(0)")+node("other","parameter(1)")+node("shared","parameter(2)")+"small = "+dtype+"[2] parameter(3)\n"+expression+"}\n";
    ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module,parse(hlo));
    Literal data = LiteralUtil::CreateR2<T>({{0,1},{static_cast<T>(maximum),static_cast<T>(high)}});
    Literal other = LiteralUtil::CreateR2<T>({{static_cast<T>(maximum),2},{3,static_cast<T>(high)}});
    Literal shared = LiteralUtil::CreateR2<T>({{static_cast<T>(maximum),1},{2,3}});
    Literal small = LiteralUtil::CreateR1<T>({static_cast<T>(maximum),3});
    std::vector<const Literal*> args{&data,&other,&shared,&small};
    HloEvaluator before_evaluator;
    ASSERT_OK_AND_ASSIGN(Literal before,before_evaluator.Evaluate(*module,args));
    const std::string original = module->ToString();
    bool changed = false;
    const bool add = family == "factor" || family == "add_broadcast" || family == "subadd_broadcast";
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
    EXPECT_EQ(changed,mode != "control" && !family.starts_with("guard_"));
    HloVerifier verifier(false,true);ASSERT_OK(verifier.Run(module.get()).status());
    HloEvaluator after_evaluator;
    ASSERT_OK_AND_ASSIGN(Literal after,after_evaluator.Evaluate(*module,args));
    std::ostringstream values;
    for (int index = 0; index < 4; ++index) {
      const int row = index/2,column = index%2;
      const uint64_t x = data.Get<T>({row,column}),y = other.Get<T>({row,column}),z = shared.Get<T>({row,column});
      const uint64_t b = small.Get<T>({recipe.axis == 0 ? row : column});
      uint64_t expected = 0;
      if (family == "factor") expected = (x+y)*z;
      if (family == "product" || family == "mul_broadcast") expected = x*6;
      if (family == "four") expected = x*y*6;
      if (family == "move") expected = x*b*2;
      if (family == "add_broadcast") expected = x+5;
      if (family == "subadd_broadcast") expected = 5-x;
      if (family == "guard_vector_constant") expected = x*(index+2)*b;
      if (family == "guard_nonbroadcast") expected = x*2*y;
      expected &= maximum;
      EXPECT_EQ(static_cast<uint64_t>(before.Get<T>({row,column})),expected);
      EXPECT_EQ(static_cast<uint64_t>(after.Get<T>({row,column})),expected);
      if (index) values << ",";
      values << static_cast<uint64_t>(after.Get<T>({row,column}));
    }
    std::cout << "MODULAR_BRIDGE_RESULT dtype=" << dtype << " case=" << recipe.name << " mode=" << mode
              << " changed=" << changed << " checked=4 values=" << values.str()
              << " rewritten_verified=1\nORIGINAL_HLO\n" << original << "REWRITTEN_HLO\n" << module->ToString();
  }
}

TEST_F(ModularBridgeReplay, CapturedOrientationsAndBroadcastAxes) {
  std::cout << std::unitbuf;
  const auto parse = [this](const std::string& hlo) {return ParseAndReturnVerifiedModule(hlo);};
  CheckBridgeType<uint8_t>("u8",parse);
  CheckBridgeType<uint32_t>("u32",parse);
  CheckBridgeType<uint64_t>("u64",parse);
}
}  // namespace
}  // namespace xla
