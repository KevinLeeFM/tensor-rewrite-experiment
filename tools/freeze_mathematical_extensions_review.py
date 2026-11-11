"""Freeze the scalar/reduction extension review without changing the original packet."""
import argparse
import json
from pathlib import Path
import zipfile
from freeze_mathematical_review import ROOT, digest, git, selection

NAME='mathematical-extensions-v1'
BRIEF='reviews/packets/'+NAME+'.md'
BASE='reviews/packets/'+NAME


def selected(revision):
    paths=set(selection(revision))
    tracked=git('ls-tree','-r','--name-only',revision).decode().splitlines()
    fixed={'tools/check_scalar_domains.py','tools/check_reduction_algebra.py',
           'tools/reduction_examples.py','tools/freeze_mathematical_review.py',
           'tools/freeze_mathematical_extensions_review.py','tests/test_scalar_domains.py',
           'tests/test_reduction_algebra.py','tests/test_theory_accounting.py',
           'docs/scalar-domains.md','docs/reduction-algebra.md','docs/mathematical-review.md',BRIEF,
           'snapshots/scalar-domains-v1.zip','snapshots/reduction-algebra-v1.zip',
           'reports/mathematical-foundation-review-closeout-v1.json'}
    for p in tracked:
        if p.startswith(('census/scalar-domains-','census/reduction-algebra-',
                         'census/reduction-mathematical-domains-',
                         'census/lean-category-overrides-','census/convolution-ordered-accounting-',
                         'reports/scalar-domains','reports/scalar-domain-',
                         'reports/reduction-algebra',
                         'reviews/results/mathematical-foundation-v1-')):
            fixed.add(p)
    paths.update(fixed)
    assert paths<=set(tracked),sorted(paths-set(tracked))
    assert all(not p.startswith(('sources/','tests/xla/','external/','.lake/')) for p in paths)
    assert all(Path(p).suffix not in {'.cc','.h','.cpp'} for p in paths)
    return sorted(paths)


def verify():
    descriptor=json.loads((ROOT/(BASE+'.json')).read_text())
    manifest_path=ROOT/descriptor['manifest'];archive_path=ROOT/descriptor['archive']
    assert digest(manifest_path.read_bytes())==descriptor['manifest_sha256']
    assert digest(archive_path.read_bytes())==descriptor['archive_sha256']
    manifest=json.loads(manifest_path.read_text());revision=descriptor['source_revision']
    assert manifest['source_revision']==revision
    assert selected(revision)==[r['path'] for r in manifest['files']]
    with zipfile.ZipFile(archive_path) as archive:
        assert sorted(archive.namelist())==[r['path'] for r in manifest['files']]
        for row in manifest['files']:
            data=archive.read(row['path'])
            assert len(data)==row['bytes'] and digest(data)==row['sha256']
            assert data==git('show',revision+':'+row['path']),row['path']
    assert descriptor['new_statements_for_review']==41
    assert not descriptor['independent_semantic_review_performed']
    assert not descriptor['code_correspondence_performed']
    print('Extension review packet verified against Git: '+str(len(manifest['files']))+' files.')


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--ref',default='HEAD')
    parser.add_argument('--verify',action='store_true');args=parser.parse_args()
    if args.verify:verify();return
    for suffix in ('.json','-manifest.json','.zip'):
        assert not (ROOT/(BASE+suffix)).exists(),'Use a new packet version; never overwrite frozen bytes'
    revision=git('rev-parse',args.ref).decode().strip();rows=[]
    with zipfile.ZipFile(ROOT/(BASE+'.zip'),'w',zipfile.ZIP_DEFLATED) as archive:
        for path in selected(revision):
            data=git('show',revision+':'+path);archive.writestr(path,data)
            rows.append(dict(path=path,sha256=digest(data),bytes=len(data)))
    manifest_path=ROOT/(BASE+'-manifest.json')
    manifest_path.write_text(json.dumps(dict(schema=1,source_revision=revision,files=rows),indent=2)+'\n')
    descriptor=dict(schema=1,status='frozen_pending_authorized_independent_review',
                    source_revision=revision,review_brief=BRIEF,archive=BASE+'.zip',
                    archive_sha256=digest((ROOT/(BASE+'.zip')).read_bytes()),
                    manifest=BASE+'-manifest.json',manifest_sha256=digest(manifest_path.read_bytes()),
                    original_reviewed_theory_statements=89,new_statements_for_review=41,
                    current_theory_statements=130,current_ledger_declarations=390,
                    current_custom_lean_lines=4598,independent_semantic_review_performed=False,
                    code_correspondence_performed=False,whole_workload_verdict='open')
    (ROOT/(BASE+'.json')).write_text(json.dumps(descriptor,indent=2)+'\n');verify()


if __name__=='__main__':main()
