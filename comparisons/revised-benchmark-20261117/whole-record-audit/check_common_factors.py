"""Exercise the exact pinned CommonFactors body on a few small, equal-product arrays."""
from pathlib import Path
import hashlib
import subprocess
import sys
import tempfile
import time

source = Path(sys.argv[1]).read_bytes()
assert hashlib.sha256(source).hexdigest() == 'ab845e9925330825efaae95b043fd4beccb4a9f29a6474ef711ef4d17d6d38c4'
text = source.decode()
begin = text.index('absl::InlinedVector<std::pair<int64_t, int64_t>, 8> CommonFactors(')
end = text.index('\nConvertedDimensionNumbers ConvertDimensionNumbers', begin)
preamble = r'''
#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <numeric>
#include <span>
#include <tuple>
#include <vector>
namespace absl {
template<class T> using Span = std::span<T>;
template<class T, size_t N> using InlinedVector = std::vector<T>;
template<class T> bool c_equal(T a, T b) {return std::ranges::equal(a,b);}
template<class T> const char* StrJoin(T,const char*) {return "";}
}
int64_t Product(std::span<const int64_t> s) {
  return std::accumulate(s.begin(),s.end(),int64_t{1},std::multiplies<>());
}
struct Check {
  bool ok;
  template<class T> Check& operator<<(T const&) {return *this;}
  ~Check() {if (!ok) std::abort();}
};
#define CHECK_EQ(a,b) Check{(a)==(b)}
'''
main = r'''
int main() {
  using V=std::vector<int64_t>;
  using P=std::vector<std::pair<int64_t,int64_t>>;
  auto check=[](V a,V b,P expected) {
    auto result=CommonFactors(a,b);
    if (result!=expected) std::abort();
    for (auto [i,j]:result) std::cout<<"("<<i<<","<<j<<") ";
    std::cout<<"\n";
  };
  check({0,2},{0,1,2},{{0,0},{1,1},{1,2},{2,3}});
  check({0},{0,0},{{0,0},{1,2}});
  check({2},{1,2},{{0,0},{0,1},{1,2}});
  check({0,2},{0,3},{{0,0},{2,2}});
}
'''
with tempfile.TemporaryDirectory() as folder:
    path = Path(folder)
    (path/'main.cc').write_text(preamble + text[begin:end] + main)
    for cmd in (['c++','-std=c++20','main.cc','-o','probe'], ['./probe']):
        start = time.monotonic()
        subprocess.run(cmd, cwd=path, check=True)
        print(f'{cmd[0]} {time.monotonic()-start:.3f}s')
