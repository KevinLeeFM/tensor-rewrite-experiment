"""Replay the explicitly curated mathematical suite, excluding source/native tasks."""
import json
from pathlib import Path
import unittest

records=json.loads(Path('reports/concatenation-family-validation-v1/commands.json').read_text())
patterns=next(row['patterns'] for row in records if row.get('exit_code')==0 and 'patterns' in row)+['test_bit_packing.py']
suite=unittest.TestSuite()
for pattern in patterns:suite.addTests(unittest.defaultTestLoader.discover('tests',pattern=pattern))
log='reports/bit-packing-validation-v1/curated-tests.log'
with Path(log).open('w') as stream:
    result=unittest.TextTestRunner(verbosity=2,stream=stream).run(suite)
summary=dict(patterns=patterns,exit_code=int(not result.wasSuccessful()),test_count=result.testsRun,log=log)
Path('reports/bit-packing-validation-v1/curated-summary.json').write_text(json.dumps(summary,indent=2)+'\n')
print(result.testsRun,'tests;',len(result.failures),'failures;',len(result.errors),'errors')
raise SystemExit(not result.wasSuccessful())
