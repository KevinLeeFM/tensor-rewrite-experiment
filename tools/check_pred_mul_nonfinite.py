"""Native IEEE arithmetic witness for a source rewrite candidate; not an XLA run."""
import hashlib,json,shutil,subprocess,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
CPP=r'''
#include <bit>
#include <cmath>
#include <cstdint>
#include <iostream>
#include <limits>
static_assert(sizeof(float)==4 && std::numeric_limits<float>::is_iec559);
int main() {
  float inputs[] = {std::numeric_limits<float>::infinity(), -std::numeric_limits<float>::infinity(), std::numeric_limits<float>::quiet_NaN(), 1.0f, -1.0f};
  std::cout << "[";
  bool first = true;
  for (bool pred : {false,true}) for (float input : inputs) {
    volatile float value=input;
    volatile float converted=static_cast<float>(pred);
    volatile float lhs=converted*value;
    float rhs=pred ? static_cast<float>(value) : 0.0f;
    if (!first) std::cout << ","; first=false;
    std::cout << "{\"predicate\":" << (pred?"true":"false")
      << ",\"input_bits\":" << std::bit_cast<uint32_t>(input)
      << ",\"lhs_bits\":" << std::bit_cast<uint32_t>(static_cast<float>(lhs))
      << ",\"rhs_bits\":" << std::bit_cast<uint32_t>(rhs)
      << ",\"lhs_nan\":" << (std::isnan(lhs)?"true":"false")
      << ",\"rhs_nan\":" << (std::isnan(rhs)?"true":"false") << "}";
  }
  std::cout << "]\n";
}
'''

def main():
    compiler=shutil.which('c++')
    if not compiler:raise RuntimeError('c++ compiler unavailable')
    flags=['-std=c++20','-O2','-fno-fast-math','-ffp-contract=off']
    with tempfile.TemporaryDirectory(prefix='pred-mul-nonfinite-') as directory:
        source=Path(directory)/'witness.cc';binary=Path(directory)/'witness'
        source.write_text(CPP)
        build=subprocess.run([compiler,*flags,str(source),'-o',str(binary)],text=True,capture_output=True)
        if build.returncode:raise RuntimeError(build.stderr)
        cases=json.loads(subprocess.check_output([str(binary)],text=True))
    mismatches=[c for c in cases if c['lhs_nan']!=c['rhs_nan']]
    assert len(mismatches)==3 and all(not c['predicate'] and c['rhs_bits']==0 for c in mismatches)
    report={'schema':1,'status':'candidate_source_rewrite_counterexample_under_strict_ieee_not_xla_reproduction',
      'source_commit':'e58e523b11f1fde802a493a776d158007486e1bf',
      'rewrite':'multiply(convert(pred),x) -> select(pred,x,0)',
      'source_handler':'HandleMultiply','source_condition':'Convert operand input type PRED, MultiplyAnyOrder; no local finite/fast-math guard',
      'compiler':compiler,'compiler_version':subprocess.check_output([compiler,'--version'],text=True),
      'flags':flags,'witness_cpp_sha256':hashlib.sha256(CPP.encode()).hexdigest(),
      'hlo_sha256':hashlib.sha256((ROOT/'tests/xla/pred_mul_nonfinite.hlo').read_bytes()).hexdigest(),
      'cases':cases,'nan_classification_mismatches':len(mismatches),
      'xla_pass_run':False,'lean_refutation_checked':False,
      'remaining':['verify pinned HLO contract and admissible nonfinite inputs',
                   'run exact pinned XLA pass with fast math disabled and confirm Select output',
                   'evaluate original and replacement through pinned HloEvaluator',
                   'construct kernel-checked floating-point refutation']}
    (ROOT/'reports/pred-mul-nonfinite.json').write_text(json.dumps(report,indent=2)+'\n')
    print('Confirmed three native IEEE NaN-classification mismatches; real-XLA replay remains pending')
if __name__=='__main__':main()
