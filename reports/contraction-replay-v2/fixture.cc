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
#include <cfenv>
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
class ContractionReplay : public HloHardwareIndependentTestBase {
 protected:
  DebugOptions GetDebugOptionsForTest() const override {
    auto options = HloHardwareIndependentTestBase::GetDebugOptionsForTest();
    options.set_xla_cpu_enable_fast_math(false);
    options.set_xla_cpu_fast_math_honor_nans(true);
    options.set_xla_cpu_fast_math_honor_infs(true);
    options.set_xla_hlo_evaluator_use_fast_path(false);
    return options;
  }
};

class InitializedDotVisitor : public AlgebraicSimplifierVisitor {
 public:
  using AlgebraicSimplifierVisitor::AlgebraicSimplifierVisitor;
  bool Initialize(HloComputation* computation,const AlgebraicSimplifierOptions& options,
                  AlgebraicSimplifier* simplifier) {
    const bool changed = Run(computation,options,simplifier);
    initializing_ = false;
    return changed;
  }
  absl::Status HandleDot(HloInstruction* dot) override {
    if (initializing_) return absl::OkStatus();
    return AlgebraicSimplifierVisitor::HandleDot(dot);
  }
 private:
  bool initializing_ = true;
};

struct Case {
  const char* name;const char* lhs;const char* rhs;const char* output;
  const char* lc;const char* rc;const char* lb;const char* rb;bool rewrite;bool layout;
};

int64_t Label(const Shape& shape,absl::Span<const int64_t> index) {
  int64_t result = 0;
  for (int i = 0; i < index.size(); ++i) result = result*shape.dimensions(i)+index[i];
  return result+1;
}

int32_t WordInput(const std::string& name,bool lhs,const Shape& shape,
                  absl::Span<const int64_t> index) {
  if (name.starts_with("batch_") || name == "rank4" || name == "matrix_contract") return Label(shape,index);
  if (name == "scalar_outer") return lhs ? 2 : index[0] == 0 ? 5 : -3;
  if (lhs) return index[0] == 0 ? 2 : -3;
  return index[0] == 0 ? 5 : index[0] == 1 ? 7 : -2;
}

int32_t Expected(const std::string& name,const Shape& lhs,const Shape& rhs,
                 absl::Span<const int64_t> index) {
  if (name == "matrix_contract") {
    int32_t sum = 0;
    for (int k = 0; k < 3; ++k) sum += Label(lhs,{index[0],k})*Label(rhs,{k,index[1]});
    return sum;
  }
  if (name == "contract_empty") return 0;
  if (name == "batch_left") return Label(lhs,{index[1],index[0]})*Label(rhs,{index[0],index[2]});
  if (name == "batch_right") return Label(lhs,{index[0],index[1]})*Label(rhs,{index[2],index[0]});
  if (name == "rank4") return Label(lhs,{index[1],index[2],index[0]})*Label(rhs,{index[3],index[0]});
  if (name == "scalar_outer") return 2*(index[0] == 0 ? 5 : -3);
  return (index[0] == 0 ? 2 : -3)*(index[1] == 0 ? 5 : index[1] == 1 ? 7 : -2);
}

TEST_F(ContractionReplay, EmptyAndOuterProductsWithCastsAndPrecisionDiagnostic) {
  std::cout << std::unitbuf;
  ASSERT_EQ(std::fegetround(),FE_TONEAREST);
  const Case cases[] = {
      {"outer00","s32[2]","s32[3]","s32[2,3]","","","","",true,false},
      {"outer01","s32[2]","s8[3]","s32[2,3]","","","","",true,false},
      {"outer10","s8[2]","s32[3]","s32[2,3]","","","","",true,false},
      {"outer11","s8[2]","s8[3]","s32[2,3]","","","","",true,false},
      {"batch_left","s32[3,2]","s32[2,4]","s32[2,3,4]","","","1","0",true,false},
      {"batch_right","s32[2,3]","s32[4,2]","s32[2,3,4]","","","0","1",true,false},
      {"rank4","s32[2,3,2]","s32[2,2]","s32[2,2,3,2]","","","2","1",true,false},
      {"matrix_contract","s32[2,3]","s32[3,4]","s32[2,4]","1","0","","",false,false},
      {"contract_empty","s32[2,0]","s32[0,3]","s32[2,3]","1","0","","",true,false},
      {"lhs_free_empty","s32[0,2]","s32[2,3]","s32[0,3]","1","0","","",true,false},
      {"rhs_free_empty","s32[2,3]","s32[3,0]","s32[2,0]","1","0","","",true,false},
      {"scalar_outer","s32[]","s32[2]","s32[2]","","","","",true,false},
      {"outer_free_empty","s32[0]","s32[3]","s32[0,3]","","","","",true,false},
      {"option_off","s32[2]","s32[3]","s32[2,3]","","","","",false,false},
      {"layout_on","s32[2]","s32[3]","s32[2,3]","","","","",true,true},
      {"f32_negative_zero","f32[2]","f32[3]","f32[2,3]","","","","",true,false},
      {"f32_positive_zero","f32[2]","f32[3]","f32[2,3]","","","","",true,false},
      {"f32_negative_result","f32[2]","f32[3]","f32[2,3]","","","","",true,false},
      {"f32_zero_option_off","f32[2]","f32[3]","f32[2,3]","","","","",false,false},
  };
  for (const Case& test : cases) for (const std::string mode : {"control","handler","pass"}) {
    SCOPED_TRACE(test.name);
    SCOPED_TRACE(mode);
    const std::string name = test.name;
    const bool fp = name.starts_with("f32_");
    const std::string hlo = "HloModule contraction\nENTRY main {\nlhs = "+std::string(test.lhs)+
        " parameter(0)\nrhs = "+test.rhs+" parameter(1)\nROOT result = "+test.output+
        " dot(lhs,rhs), lhs_contracting_dims={"+test.lc+"}, rhs_contracting_dims={"+test.rc+
        "}, lhs_batch_dims={"+test.lb+"}, rhs_batch_dims={"+test.rb+"}\n}\n";
    ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module,ParseAndReturnVerifiedModule(hlo));
    ASSERT_FALSE(module->config().debug_options().xla_cpu_enable_fast_math());
    ASSERT_TRUE(module->config().debug_options().xla_cpu_fast_math_honor_nans());
    ASSERT_TRUE(module->config().debug_options().xla_cpu_fast_math_honor_infs());
    const Shape& ls = module->entry_computation()->parameter_instruction(0)->shape();
    const Shape& rs = module->entry_computation()->parameter_instruction(1)->shape();
    Literal lhs = Literal::CreateFromShape(ls);Literal rhs = Literal::CreateFromShape(rs);
    if (fp) {
      ASSERT_OK(lhs.Populate<float>([&](absl::Span<const int64_t> index) {
        if (name == "f32_negative_result") return index[0] == 0 ? -2.0f : 3.0f;
        if (name == "f32_positive_zero") return 0.0f;
        return index[0] == 0 ? std::bit_cast<float>(uint32_t{0x80000000}) : 0.0f;
      }));
      ASSERT_OK(rhs.Populate<float>([](absl::Span<const int64_t> index) {return float(index[0]+1);}));
    } else {
      if (ls.element_type() == S8) {
        ASSERT_OK(lhs.Populate<int8_t>([&](absl::Span<const int64_t> i) {return int8_t(WordInput(name,true,ls,i));}));
      } else {ASSERT_OK(lhs.Populate<int32_t>([&](absl::Span<const int64_t> i) {return WordInput(name,true,ls,i);}));}
      if (rs.element_type() == S8) {
        ASSERT_OK(rhs.Populate<int8_t>([&](absl::Span<const int64_t> i) {return int8_t(WordInput(name,false,rs,i));}));
      } else {ASSERT_OK(rhs.Populate<int32_t>([&](absl::Span<const int64_t> i) {return WordInput(name,false,rs,i);}));}
    }
    std::vector<const Literal*> args{&lhs,&rhs};
    HloEvaluator before_evaluator;before_evaluator.set_use_fast_path(false);
    ASSERT_OK_AND_ASSIGN(Literal before,before_evaluator.Evaluate(*module,args));
    const std::string original = module->ToString();
    bool changed = false;
    if (mode != "control") {
      AlgebraicSimplifierOptions options;options.set_run_to_fixed_point(false);
      options.set_is_layout_sensitive(test.layout);options.set_enable_fast_math(false);
      options.set_enable_dot_to_multiply_rewrite(test.rewrite);options.set_enable_dot_strength_reduction(false);
      AlgebraicSimplifier simplifier(options);
      if (mode == "handler") {
        InitializedDotVisitor visitor(options,&simplifier);
        ASSERT_FALSE(visitor.Initialize(module->entry_computation(),options,&simplifier));
        ASSERT_EQ(original,module->ToString());
        ASSERT_OK(visitor.HandleDot(module->entry_computation()->root_instruction()));
        changed = visitor.changed();
      } else {ASSERT_OK_AND_ASSIGN(changed,simplifier.Run(module.get()));}
    }
    const bool expected_change = mode != "control" && test.rewrite && !test.layout;
    EXPECT_EQ(changed,expected_change);
    HloVerifier verifier(false,true);ASSERT_OK(verifier.Run(module.get()).status());
    HloEvaluator after_evaluator;after_evaluator.set_use_fast_path(false);
    ASSERT_OK_AND_ASSIGN(Literal after,after_evaluator.Evaluate(*module,args));
    if (!fp) {
      int checked = 0;std::ostringstream values;
      after.EachCell<int32_t>([&](absl::Span<const int64_t> index,int32_t value) {
        EXPECT_EQ(value,Expected(name,ls,rs,index));EXPECT_EQ(before.Get<int32_t>(index),value);
        if (checked++) values << ",";
        values << value;
      });
      std::cout << "CONTRACTION_RESULT case=" << name << " mode=" << mode << " changed=" << changed
                << " checked=" << checked << " values=" << (checked ? values.str() : "empty")
                << " rewritten_verified=1\n";
    } else {
      int checked = 0;std::ostringstream old_bits,new_bits;bool equal = true;
      after.EachCell<float>([&](absl::Span<const int64_t> index,float value) {
        const float old = before.Get<float>(index);const auto a = std::bit_cast<uint32_t>(old);
        const auto b = std::bit_cast<uint32_t>(value);equal &= a == b;EXPECT_EQ(old,value);
        if (name != "f32_negative_result") {
          EXPECT_EQ(a,0);
          EXPECT_EQ(b,name == "f32_negative_zero" && expected_change && index[0] == 0 ? uint32_t{0x80000000} : 0);
        }
        if (checked++) {old_bits << ",";new_bits << ",";}
        old_bits << a;new_bits << b;
      });
      std::cout << "CONTRACTION_FP_RESULT case=" << name << " mode=" << mode << " changed=" << changed
                << " before=" << old_bits.str() << " after=" << new_bits.str() << " bits_equal=" << equal
                << " numeric_equal=1 rewritten_verified=1 rne=1\n";
    }
    std::cout << "ORIGINAL_HLO\n" << original << "REWRITTEN_HLO\n" << module->ToString();
  }
}
}  // namespace
}  // namespace xla
