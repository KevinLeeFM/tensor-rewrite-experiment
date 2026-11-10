"""Check archived finite scalar/Select observations; does not execute XLA."""
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = [('0','0','12','12'),('0','1','8','8'),('1','0','12','24'),('1','1','8','24')]


def check_archive(root=ROOT):
    folder=root/'reports/scalar-select-replay-v2'
    result=json.loads((folder/'result.json').read_text())
    assert result['status']=='real_xla_scalar_select_value_changes_reproduced'
    assert result['test_passed'] and result['xla_pass_run'] and result['exit_code']==0
    assert result['source_commit']==json.loads((root/'sources/manifest.json').read_text())['xla_commit']
    files=result['files']
    assert len(files)==6 and {Path(f['path']).name for f in files}=={
        'fixture.cc','BUILD','events.json','build.log','test.log','test.xml'}
    for item in files:
        path=root/item['path']
        assert path.parent==folder
        assert hashlib.sha256(path.read_bytes()).hexdigest()==item['sha256']
    source=root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'
    assert hashlib.sha256(source.read_bytes()).hexdigest()==result['pass_source_sha256']
    log=(folder/'test.log').read_text()
    rows=re.findall(r'^SCALAR_SELECT_RESULT enabled=([01]) predicate=([01]) before=([0-9]+) after=([0-9]+) rewritten_verified=1 fast_math=0$',log,re.M)
    assert sorted(rows)==EXPECTED
    assert sorted((str(int(c['enabled'])),str(int(c['predicate'])),str(c['before']),str(c['after']))
                  for c in result['cases'])==EXPECTED
    assert all(c['rewritten_verified'] for c in result['cases'])
    assert log.count('ORIGINAL_HLO')==log.count('REWRITTEN_HLO')==4
    # In the isolated run the original convolution remains, with the Select's
    # scale operands removed and six moved to the output. Controls keep scaling.
    assert log.count('select(%predicate, %input, %input)')==2
    assert log.count('constant(6)')==2
    assert 'window={size=4}, dim_labels=b0f_0io->b0f' in log
    fixture=(folder/'fixture.cc').read_text()
    for anchor in ('options.set_is_layout_sensitive(true);',
                   'options.set_enable_scalar_multiply_reduction(enabled);',
                   'options.set_enable_fast_math(false);',
                   'EXPECT_EQ(changed, enabled);',
                   'ASSERT_OK(verifier.Run(module.get()).status());'):
        assert anchor in fixture
    events=[json.loads(line) for line in (folder/'events.json').read_text().splitlines()]
    assert any(e.get('finished',{}).get('overallSuccess') for e in events)
    assert any(e.get('testResult',{}).get('status')=='PASSED' for e in events)
    assert any(e.get('testSummary',{}).get('overallStatus')=='PASSED' for e in events)
    xml=ET.parse(folder/'test.xml')
    assert len(xml.findall('.//testcase'))==1
    assert not xml.findall('.//failure') and not xml.findall('.//error')


if __name__=='__main__':
    check_archive()
    print('Archived scalar/Select finite value changes and disabled-option controls verified; no new XLA run')
