"""Freeze a fresh census/pilot review packet, including the executable Python suite."""
from pathlib import Path
import datetime,hashlib,json,sys,zipfile
import argparse
parser=argparse.ArgumentParser()
parser.add_argument('--version',type=int,required=True)
args=parser.parse_args()
assert args.version>=2, 'v1 is immutable'
root=Path(__file__).resolve().parents[1]
assert Path.cwd()==root, 'run from experiment root'
out=Path('reviews/packets');stem='census-pilot-v'+str(args.version)
archive=out/(stem+'.zip');manifest_path=out/(stem+'-manifest.json');descriptor=out/(stem+'.json')
assert (out/(stem+'.md')).exists(), 'write packet scope before freezing'
assert not archive.exists() and not manifest_path.exists() and not descriptor.exists()
checkpoint=json.loads(Path('reports/initial-checkpoint.json').read_text())
assert checkpoint['checks_passed']
for f in checkpoint['files']:assert hashlib.sha256(Path(f['path']).read_bytes()).hexdigest()==f['sha256'],f['path']
paths={Path('TensorRewrite.lean'),Path('lakefile.toml'),Path('lake-manifest.json'),Path('lean-toolchain'),Path('requirements-parser.txt'),out/(stem+'.md')}
for base in ('TensorRewrite','census','sources/xla','tests','tools','.parser-deps'):
 for p in Path(base).rglob('*'):
  if p.is_file() and '__pycache__' not in p.parts:paths.add(p)
assert Path('tests/test_tools.py') in paths
from checkpoint import validate_test_count
validate_test_count(checkpoint['checks']['tests']['stdout']+checkpoint['checks']['tests']['stderr'])
# Include authenticated completed reviews referenced by source finding records.
resolution_path=Path('reviews/census-pilot-v1-resolution.json')
if resolution_path.exists():
 resolution=json.loads(resolution_path.read_text());paths.add(resolution_path)
 reviews=[dict(path=resolution['independent_review'],sha256=resolution['review_sha256'])]
 reviews+=resolution.get('supplements',[])
 reviews += [resolution[key] for key in ('helper_inventory_review','source_census_closure_review') if key in resolution]
 reviews+=resolution.get('source_normalization_reviews',[])
 for review in reviews:
  reviewed_path=Path(review['path'])
  assert hashlib.sha256(reviewed_path.read_bytes()).hexdigest()==review['sha256']
  paths.add(reviewed_path)
  if 'companion' in review:
   companion=Path(review['companion'])
   assert hashlib.sha256(companion.read_bytes()).hexdigest()==review['companion_sha256']
   paths.add(companion)
paths|=set(Path('sources').glob('*.json'))
paths|=set(Path('reports').glob('*.md'))|set(Path('reports').glob('*.json'))
# Freeze native archives, including failures, while keeping multi-gigabyte raw
# compiler-output material in its already hash-pinned separate archive.
for p in Path('reports').glob('*/result.json'):
 r=json.loads(p.read_text())
 if p.parent.name in ('typed-ast-v1','compile-query-typed-ast-v1','dependencies-typed-ast-v1'):continue
 # Early native archives used an older schema without pass_source_sha256.
 # Include them too: later offline evidence checkers depend on those runs.
 for f in p.parent.iterdir():
  if f.is_file():paths.add(f)
manifest=dict(schema=1,source_commit=json.loads(Path('sources/manifest.json').read_text())['xla_commit'],status='frozen_review_inputs_not_review_result',created_at_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),files=[dict(path=str(p),bytes=p.stat().st_size,sha256=hashlib.sha256(p.read_bytes()).hexdigest()) for p in sorted(paths)])
manifest_path.write_text(json.dumps(manifest,indent=2)+'\n')
with zipfile.ZipFile(archive,'x',compression=zipfile.ZIP_DEFLATED) as z:
 for p in sorted(paths):z.write(p,str(p))
 z.write(manifest_path,str(manifest_path))
with zipfile.ZipFile(archive) as z:
 for f in manifest['files']:assert hashlib.sha256(z.read(f['path'])).hexdigest()==f['sha256']
report=dict(schema=1,status='ready_for_independent_review_not_reviewed',packet=str(out/(stem+'.md')),archive=str(archive),archive_sha256=hashlib.sha256(archive.read_bytes()).hexdigest(),archive_bytes=archive.stat().st_size,manifest=str(manifest_path),manifest_sha256=hashlib.sha256(manifest_path.read_bytes()).hexdigest(),input_files=len(paths),source_schema_count=len(json.loads(Path('census/site-case-map.json').read_text())['bindings']),accepted_source_rewrites=0,semantic_denominator=None,reviewer_assigned=False,review_result=None)
descriptor.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
