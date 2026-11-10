/* Copyright 2026 The OpenXLA Authors.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
is distributed under the License on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */
#include <cmath>
#include <iostream>
#include <limits>
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
class CompareNonnegativeReplay : public HloHardwareIndependentTestBase {
 protected:
  DebugOptions GetDebugOptionsForTest() const override {
    auto options=HloHardwareIndependentTestBase::GetDebugOptionsForTest();
    options.set_xla_cpu_enable_fast_math(false);
    options.set_xla_cpu_fast_math_honor_nans(true);
    options.set_xla_cpu_fast_math_honor_infs(true);
    options.set_xla_hlo_evaluator_use_fast_path(false);
    return options;
  }
};
class InitializedCompareVisitor : public AlgebraicSimplifierVisitor {
 public:
  using AlgebraicSimplifierVisitor::AlgebraicSimplifierVisitor;
  bool Initialize(HloComputation* c,const AlgebraicSimplifierOptions& options,
                  AlgebraicSimplifier* simplifier) {
    const bool changed=Run(c,options,simplifier);
    initializing_=false;
    return changed;
  }
  absl::Status HandleCompare(HloInstruction* compare) override {
    if (initializing_) return absl::OkStatus();
    return AlgebraicSimplifierVisitor::HandleCompare(compare);
  }
 private:
  bool initializing_=true;
};
TEST_F(CompareNonnegativeReplay, StrictNanAndFiniteControls) {
  const float inputs[]={std::numeric_limits<float>::quiet_NaN(),-1.0f,0.0f,1.0f,
                        std::numeric_limits<float>::infinity(),
                        -std::numeric_limits<float>::infinity()};
  for (const std::string kind : {"abs","exp","square","maximum","parameter"})
  for (const std::string direction : {"GE","LE","LT","GT"})
  for (const std::string mode : {"control","handler","pass"}) {
    std::string operation;
    if (kind=="abs") operation="abs(p)";
    else if (kind=="exp") operation="exponential(p)";
    else if (kind=="square") operation="multiply(p,p)";
    else if (kind=="maximum") operation="maximum(p,z)";
    else operation="reshape(p)";
    const std::string arguments=(direction=="GE" || direction=="LT") ? "v,z" : "z,v";
    const std::string hlo="HloModule compare_nonnegative\nENTRY main {\n"
        "p = f32[6] parameter(0)\nzero = f32[] constant(0)\n"
        "z = f32[6] broadcast(zero), dimensions={}\n"+(kind=="parameter" ? std::string("") : "v = f32[6] "+operation)+
        "\nROOT result = pred[6] compare("+(kind=="parameter" ? ((direction=="GE" || direction=="LT") ? std::string("p,z") : std::string("z,p")) : arguments)+"), direction="+direction+"\n}";
    ASSERT_OK_AND_ASSIGN(std::unique_ptr<HloModule> module,ParseAndReturnVerifiedModule(hlo));
    ASSERT_FALSE(module->config().debug_options().xla_cpu_enable_fast_math());
    ASSERT_TRUE(module->config().debug_options().xla_cpu_fast_math_honor_nans());
    ASSERT_TRUE(module->config().debug_options().xla_cpu_fast_math_honor_infs());
    Literal input=LiteralUtil::CreateR1<float>(inputs);
    std::vector<const Literal*> arguments_literal{&input};
    HloEvaluator evaluator;evaluator.set_use_fast_path(false);
    ASSERT_OK_AND_ASSIGN(Literal before,evaluator.Evaluate(*module,arguments_literal));
    const std::string original=module->ToString();
    bool changed=false;
    if (mode!="control") {
      AlgebraicSimplifierOptions options;options.set_enable_fast_math(false);
      options.set_run_to_fixed_point(false);
      AlgebraicSimplifier simplifier(options);
      if (mode=="handler") {
        InitializedCompareVisitor visitor(options,&simplifier);
        ASSERT_FALSE(visitor.Initialize(module->entry_computation(),options,&simplifier));
        ASSERT_EQ(original,module->ToString());
        ASSERT_OK(visitor.HandleCompare(module->entry_computation()->root_instruction()));
        changed=visitor.changed();
      } else {ASSERT_OK_AND_ASSIGN(changed,simplifier.Run(module.get()));}
    }
    HloVerifier verifier(false,true);ASSERT_OK(verifier.Run(module.get()).status());
    HloEvaluator after_evaluator;after_evaluator.set_use_fast_path(false);
    ASSERT_OK_AND_ASSIGN(Literal after,after_evaluator.Evaluate(*module,arguments_literal));
    const bool true_fold=direction=="GE" || direction=="LE";
    const bool candidate=kind!="parameter";
    std::string first,second;
    for (int i=0;i<6;++i) {
      const bool b=before.Get<bool>({i});const bool a=after.Get<bool>({i});
      if (i) {first+=",";second+=",";}
      first+=b?'1':'0';second+=a?'1':'0';
      if (candidate) {
        EXPECT_EQ(b,i!=0 && true_fold);
        EXPECT_EQ(a,mode!="control" ? true_fold : b);
      } else {EXPECT_EQ(a,b);}
    }
    if (candidate) EXPECT_EQ(changed,mode!="control");
    std::cout<<"NONNEG_COMPARE_RESULT kind="<<kind<<" direction="<<direction
             <<" mode="<<mode<<" changed="<<changed<<" before="<<first
             <<" after="<<second<<" rewritten_verified=1 cpu_fast_math=0 honor_nans=1"
             <<" honor_infs=1 evaluator_fast_path=0 simplifier_fast_math=0\n"
             <<"ORIGINAL_HLO\n"<<original<<"\nREWRITTEN_HLO\n"<<module->ToString()<<"\n";
  }
}
}  // namespace
}  // namespace xla
