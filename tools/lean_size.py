"""Count physical lines containing Lean code; version 1, strict lexical subset.

Supports nested comments, ordinary/raw strings, escaped identifiers,
and character literals. Interpolated strings are rejected pending support for
their embedded Lean expressions. This is source LOC, not proof-term size.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re


def count_source(text):
    lines = set()
    i, line, depth = 0, 1, 0
    mode, hashes = 'code', ''
    while i < len(text):
        c = text[i]
        if depth:
            if text.startswith('/-', i):
                depth += 1
                i += 2
                continue
            if text.startswith('-/', i):
                depth -= 1
                i += 2
                continue
        elif mode != 'code':
            if not c.isspace():
                lines.add(line)
            if mode == 'raw' and text.startswith('"' + hashes, i):
                i += 1 + len(hashes)
                mode = 'code'
                continue
            if mode in ('string', 'identifier') and c == ('"' if mode == 'string' else '»'):
                mode = 'code'
            elif mode == 'string' and c == '\\':
                if i + 1 >= len(text):
                    raise ValueError('unterminated string escape')
                if text[i + 1] == '\n':
                    line += 1
                i += 2
                continue
        elif text.startswith('--', i):
            end = text.find('\n', i)
            i = len(text) if end < 0 else end
            continue
        elif text.startswith('/-', i):
            depth = 1
            i += 2
            continue
        else:
            if not c.isspace():
                lines.add(line)
            if text.startswith('s!"', i) or text.startswith('m!"', i):
                raise ValueError('interpolated strings require a compiler-backed counter')
            raw = re.match(r'r(#+)?"', text[i:])
            if raw and (i == 0 or not (text[i-1].isalnum() or text[i-1] == '_')):
                mode, hashes = 'raw', raw[1] or ''
                i += len(raw[0])
                continue
            if c == '"':
                mode = 'string'
            elif c == '«':
                mode = 'identifier'
            elif c == "'":
                char = re.match(r"'(?:\\(?:u[0-9a-fA-F]{4}|x[0-9a-fA-F]{2}|.)|[^'\\\n])'", text[i:])
                if char:
                    i += len(char[0])
                    continue
        if c == '\n':
            line += 1
        i += 1
    if depth or mode != 'code':
        raise ValueError(f'unterminated lexical construct: comment_depth={depth}, mode={mode}')
    return {'physical_lines': len(text.splitlines()), 'code_lines': len(lines)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('paths', nargs='+', type=Path)
    args = parser.parse_args()
    files = sorted({p.resolve() for path in args.paths for p in
                    (path.rglob('*.lean') if path.is_dir() else [path])})
    rows = []
    for path in files:
        data = path.read_bytes()
        rows.append({'path': str(path), 'sha256': hashlib.sha256(data).hexdigest(),
                     **count_source(data.decode())})
    print(json.dumps({'counter_version': 1, 'files': rows,
                      'total_code_lines': sum(r['code_lines'] for r in rows)}, indent=2))


if __name__ == '__main__':
    main()
