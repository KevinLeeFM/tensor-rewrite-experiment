"""Lexical discovery inventory. Entries are candidates, never a frozen rewrite census."""
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc"


def mask_cpp(text):
    """Mask comments/strings, preserving offsets/newlines for site discovery."""
    pattern = re.compile(r'//[^\n]*|/\*[\s\S]*?\*/|R"([^ ()\\\t\r\n]{0,16})\([\s\S]*?\)\1"|"(?:\\[\s\S]|[^"\\])*"|\'(?:\\[\s\S]|[^\'\\])*\'')
    return pattern.sub(lambda m: ''.join('\n' if c == '\n' else ' ' for c in m[0]), text)


def inventory(text):
    masked = mask_cpp(text)
    # Qualified visitor definitions; brace matching includes nested branches/lambdas.
    definitions = []
    for match in re.finditer(r'\bAlgebraicSimplifierVisitor::(\w+)\s*\(', masked):
        start = masked.find('{', match.end())
        semicolon = masked.find(';', match.end())
        if start < 0 or 0 <= semicolon < start:
            continue
        depth, end = 1, start + 1
        while end < len(masked) and depth:
            depth += (masked[end] == '{') - (masked[end] == '}')
            end += 1
        assert depth == 0
        definitions.append({"name": match[1], "start": match.start(), "end": end,
                            "line": text.count('\n', 0, match.start()) + 1,
                            "end_line": text.count('\n', 0, end) + 1})
    # Broad mutation vocabulary deliberately includes construction and metadata sites.
    mutation = re.compile(r'\b(\w*(?:Replace|Remove|AddInstruction|set_|mutable_|Swap|Clone|UpdateLayout|SetAndSanitize)\w*)\s*\(')
    sites = []
    for match in mutation.finditer(masked):
        line = text.count('\n', 0, match.start()) + 1
        owner = next((d['name'] for d in definitions if d['start'] <= match.start() < d['end']), None)
        call = match[1]
        kind = 'replacement' if 'Replace' in call else 'mutation_or_construction'
        sites.append({"id": f"site-L{line:05d}-C{match.start() - masked.rfind(chr(10),0,match.start()):03d}",
                      "line": line, "call": call, "owner": owner, "kind": kind,
                      "review_status": "unreviewed", "obligation_ids": []})
    return {"schema": 1, "status": "discovery_only", "denominator_frozen": False,
            "source_sha256": hashlib.sha256(text.encode()).hexdigest(),
            "limitations": ["lexical inventory, not a C++ AST", "helper calls and indirect mutations require manual tracing",
                            "sites do not correspond one-to-one to rewrites", "no independent reconciliation yet"],
            "definitions": [{k:v for k,v in d.items() if k not in ('start','end')} for d in definitions],
            "sites": sites}


def main():
    data = inventory(SOURCE.read_text())
    output = ROOT / 'census/source-sites.json'
    output.write_text(json.dumps(data, indent=2) + '\n')
    handlers = sum(d['name'].startswith('Handle') for d in data['definitions'])
    print(f"{handlers} handlers, {len(data['sites'])} candidate sites; census remains open")


if __name__ == '__main__':
    main()
