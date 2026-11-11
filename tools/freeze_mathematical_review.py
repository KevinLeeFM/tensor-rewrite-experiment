"""Freeze a mathematical-only review packet from a committed Git snapshot."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import zipfile

ROOT=Path(__file__).resolve().parents[1]
NAME='mathematical-foundation-v1'
BRIEF='reviews/packets/'+NAME+'.md'


def git(*args):
    return subprocess.check_output(['git',*args],cwd=ROOT)


def digest(data):return hashlib.sha256(data).hexdigest()


def selection(revision):
    tracked=git('ls-tree','-r','--name-only',revision).decode().splitlines()
    fixed={'AGENTS.md','README.md','lakefile.toml','lake-manifest.json','lean-toolchain','.gitignore',
           'TensorRewrite.lean','TensorRewriteLibraries.lean','TensorRewriteTheory.lean',
           'tools/lean_size.py','tools/check_libraries.py','tools/check_theory.py',
           'tools/check_logical_family.py','tools/check_convolution_model.py',
           'tools/check_convolution_pointwise.py','tools/check_convolution_dot.py',
           'tools/check_convolution_separable.py','tools/check_convolution_ordered.py',
           'tools/convolution_examples.py','tools/ordered_float_examples.py','tools/mathematical_ledger.py',
           'tests/test_logical_family.py','tests/test_mathematical_ledger.py',
           'census/pilot-value-proofs.json','census/mathematical-corpus-v1.json',
           'census/mathematical-ledger.json','census/convolution-mathematical-domains-v1.json',
           'census/logical-values-family-v1.json','snapshots/convolution-model-v1.zip',
           'snapshots/convolution-ordered-v1.zip','reports/library-setup.json',
           'reports/theory-progress.json','reports/logical-values-family.json',
           'reports/convolution-model.json','reports/convolution-model-v1.json',
           'reports/convolution-pointwise.json','reports/convolution-dot.json',
           'reports/convolution-separable.json','reports/convolution-ordered.json',
           'reports/convolution-ordered-v1-failed.json','reports/mathematical-ledger-audit.lean',
           'reports/mathematical-ledger-audit.log','docs/theory-scope.md','docs/dependencies.md',
           'docs/experiment-plan.md','docs/agent-campaign-protocol.md','docs/lean-size-protocol.md',
           'docs/mathematical-families.md'}
    corpus=json.loads(git('show',revision+':census/mathematical-corpus-v1.json'))
    fixed.update(f['path'] for f in corpus['files'])
    for p in tracked:
        if (p.startswith('TensorRewrite/') and p.endswith('.lean') or
            p.startswith('tests/fixtures/') and p.endswith('.lean') or
            p.startswith('tests/test_convolution') and p.endswith('.py') or
            p.startswith('census/convolution-') and '-v' in p and p.endswith('.json') or
            p.startswith('docs/convolution-') and p.endswith('.md') or
            p.startswith('docs/lean-style-guide/') or
            p in {'reports/typed-logical-family-v1.md','reports/exact-convolution-model.md',
                  'reports/pointwise-convolution-reduction.md','reports/convolution-dot-bridge.md',
                  'reports/convolution-separable-reduction.md','reports/ordered-convolution-numerics.md'}):
            fixed.add(p)
    assert fixed<=set(tracked),sorted(fixed-set(tracked))
    assert all(not p.startswith(('sources/','tests/xla/','reports/xla-')) for p in fixed)
    assert all(Path(p).suffix not in ('.cc','.h') for p in fixed)
    return sorted(fixed)


def verify():
    descriptor=json.loads((ROOT/('reviews/packets/'+NAME+'.json')).read_text())
    manifest_path=ROOT/descriptor['manifest'];archive_path=ROOT/descriptor['archive']
    assert digest(manifest_path.read_bytes())==descriptor['manifest_sha256']
    assert digest(archive_path.read_bytes())==descriptor['archive_sha256']
    manifest=json.loads(manifest_path.read_text())
    with zipfile.ZipFile(archive_path) as archive:
        assert sorted(archive.namelist())==sorted(f['path'] for f in manifest['files'])
        for file in manifest['files']:
            data=archive.read(file['path'])
            assert len(data)==file['bytes'] and digest(data)==file['sha256'],file['path']
    assert not descriptor['independent_semantic_review_performed']
    assert not descriptor['code_correspondence_performed']
    print('Frozen mathematical packet verified: '+str(len(manifest['files']))+' files.')


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--ref');parser.add_argument('--verify',action='store_true')
    args=parser.parse_args()
    if args.verify:verify();return
    assert args.ref,'--ref required for freezing'
    revision=git('rev-parse',args.ref+'^{commit}').decode().strip()
    target=ROOT/'reviews/packets'/NAME
    archive_path=target.with_suffix('.zip');manifest_path=target.with_name(NAME+'-manifest.json')
    descriptor_path=target.with_suffix('.json')
    assert not any(p.exists() for p in (archive_path,manifest_path,descriptor_path))
    rows=[]
    with zipfile.ZipFile(archive_path,'x',compression=zipfile.ZIP_DEFLATED) as archive:
        for name in selection(revision)+[BRIEF]:
            data=(ROOT/name).read_bytes() if name==BRIEF else git('show',revision+':'+name)
            archive.writestr(name,data)
            rows.append(dict(path=name,bytes=len(data),sha256=digest(data),
                             origin='review_brief' if name==BRIEF else 'committed_mathematical_snapshot'))
    manifest=dict(schema=1,source_revision=revision,code_correspondence='future_work',files=rows)
    manifest_path.write_text(json.dumps(manifest,indent=2)+'\n')
    descriptor=dict(schema=1,status='frozen_pending_independent_mathematical_review',
        source_revision=revision,archive=str(archive_path.relative_to(ROOT)),
        archive_sha256=digest(archive_path.read_bytes()),manifest=str(manifest_path.relative_to(ROOT)),
        manifest_sha256=digest(manifest_path.read_bytes()),review_brief=BRIEF,
        independent_semantic_review_performed=False,code_correspondence_performed=False,
        code_correspondence_future_work=True,whole_workload_verdict='open')
    descriptor_path.write_text(json.dumps(descriptor,indent=2)+'\n');verify()


if __name__=='__main__':main()
