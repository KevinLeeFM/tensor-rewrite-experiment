"""Compile exact pinned composition template with span/check compatibility shims.
This is a native source smoke/control test, not a full XLA build or C++ proof.
"""
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
ROOT=Path(__file__).resolve().parents[1]


def main():
    compiler=shutil.which('c++')
    if not compiler: raise RuntimeError('c++ compiler unavailable')
    source=(ROOT/'sources/xla/xla/permutation_util.h').read_text()
    start=source.index('template <typename Container>\nContainer ComposePermutations(')
    end=source.index('\ntemplate <typename Container>\nbool IsIdentityPermutation',start)
    template=source[start:end]
    assert template.count('output.push_back(p1[p2[i]]);')==1
    prefix='''#include <algorithm>
#include <cassert>
#include <cstdint>
#include <iostream>
#include <numeric>
#include <span>
#include <vector>
namespace absl { template<class T> using Span = std::span<T>; }
#define CHECK_EQ(a,b) assert((a)==(b))
'''
    harness='''
int main() {
  int64_t checked = 0;
  for (int64_t n = 0; n <= 5; ++n) {
    std::vector<int64_t> p(n); std::iota(p.begin(), p.end(), 0);
    do {
      std::vector<int64_t> q(n); std::iota(q.begin(), q.end(), 0);
      do {
        auto actual = ComposePermutations<std::vector<int64_t>>(p, q);
        if (actual.size() != p.size()) return 2;
        for (int64_t i = 0; i < n; ++i) {
          if (actual[i] != p[q[i]]) { std::cerr << "composition mismatch"; return 3; }
        }
        ++checked;
      } while (std::next_permutation(q.begin(), q.end()));
    } while (std::next_permutation(p.begin(), p.end()));
  }
  std::cout << checked << "\\n";
}
'''
    report={'schema':1,'status':'native_extracted_template_control_not_full_xla',
            'header_sha256':hashlib.sha256(source.encode()).hexdigest(),
            'template_sha256':hashlib.sha256(template.encode()).hexdigest(),
            'compiler':compiler,'compiler_version':subprocess.check_output([compiler,'--version'],text=True),
            'rank_limit':5,'compatibility_shims':['absl::Span -> std::span','CHECK_EQ -> assert'],
            'runs':{}}
    with tempfile.TemporaryDirectory(prefix='tensor-permutation-') as temp:
        path=Path(temp)
        for name,body in [('original',template),('swapped_mutant',template.replace('p1[p2[i]]','p2[p1[i]]'))]:
            cpp=path/(name+'.cc');binary=path/name
            cpp.write_text(prefix+body+harness)
            build=subprocess.run([compiler,'-std=c++20','-O2',str(cpp),'-o',str(binary)],text=True,capture_output=True)
            if build.returncode: raise RuntimeError(build.stderr)
            run=subprocess.run([str(binary)],text=True,capture_output=True)
            report['runs'][name]={'exit_code':run.returncode,'stdout':run.stdout,'stderr':run.stderr}
        assert report['runs']['original']['exit_code']==0
        assert int(report['runs']['original']['stdout'])==15018
        assert report['runs']['swapped_mutant']['exit_code']==3
        assert report['runs']['swapped_mutant']['stderr']=='composition mismatch'
    (ROOT/'reports/native-permutation.json').write_text(json.dumps(report,indent=2)+'\n')
    print('Native extracted routine: 15018 permutation pairs checked; swapped-index mutant rejected')

if __name__=='__main__':main()
