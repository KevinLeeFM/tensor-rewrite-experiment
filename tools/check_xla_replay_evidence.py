"""Offline integrity check for archived real-XLA replay evidence; not a new run."""
import hashlib,json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def main():
 folder=ROOT/'reports/xla-replay-v2'
 result=json.loads((folder/'result.json').read_text())
 assert result['source_commit']==json.loads((ROOT/'sources/manifest.json').read_text())['xla_commit']
 for name,expected in result['files'].items():
  assert hashlib.sha256((folder/name).read_bytes()).hexdigest()==expected,name
 text=(folder/'test.log').read_text()
 observations=re.findall(r'PRED_MUL_RESULT input=(\w+) swapped=([01]) before_nan=1 after_zero=1',text)
 expected={(name,str(order)) for name in ('positive_infinity','negative_infinity','quiet_nan') for order in (0,1)}
 assert len(observations)==6 and set(observations)==expected
 assert text.count('ORIGINAL_HLO')==text.count('REWRITTEN_HLO')==6
 events=[json.loads(line) for line in (folder/'xla-replay-expanded-events.json').read_text().splitlines()]
 assert any(e.get('finished',{}).get('overallSuccess') for e in events)
 assert any(e.get('testResult',{}).get('status')=='PASSED' for e in events)
 assert any(e.get('testSummary',{}).get('overallStatus')=='PASSED' for e in events)
 strict_folder=ROOT/'reports/xla-replay-v3'
 strict=json.loads((strict_folder/'result.json').read_text())
 for name,digest in strict['files'].items():
  assert hashlib.sha256((strict_folder/name).read_bytes()).hexdigest()==digest,name
 profile={'cpu_fast_math':False,'honor_nans':True,'honor_infs':True,'evaluator_fast_path':False,'algebraic_simplifier_fast_math':False}
 assert strict['numerical_profile']==profile
 strict_text=(strict_folder/'test.log').read_text()
 rows=re.findall(r'PRED_MUL_RESULT input=(\w+) swapped=([01]) before_nan=1 after_zero=1 cpu_fast_math=0 honor_nans=1 honor_infs=1 evaluator_fast_path=0',strict_text)
 assert len(rows)==6 and set(rows)==expected
 strict_events=[json.loads(line) for line in (strict_folder/'xla-replay-strict-events.json').read_text().splitlines()]
 assert any(e.get('finished',{}).get('overallSuccess') for e in strict_events)
 assert any(e.get('testResult',{}).get('status')=='PASSED' for e in strict_events)
 pass_source=ROOT/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'
 assert strict['pass_source_sha256']==hashlib.sha256(pass_source.read_bytes()).hexdigest()
 manifest=json.loads((ROOT/'sources/numerical-contract-manifest.json').read_text())
 for item in manifest['files']:
  assert hashlib.sha256((ROOT/item['path']).read_bytes()).hexdigest()==item['sha256']
 print('Pinned-XLA archives verified: six witnesses in both baseline and explicit strict-module configurations; no new pass run')
if __name__=='__main__':main()
