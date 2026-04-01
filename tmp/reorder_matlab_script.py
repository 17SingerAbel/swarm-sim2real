#!/usr/bin/env python3
import re, sys
from pathlib import Path

if len(sys.argv) != 3:
    print('usage: reorder_matlab_script.py <infile> <outfile>')
    sys.exit(1)

infile = Path(sys.argv[1])
outfile = Path(sys.argv[2])
lines = infile.read_text(encoding='utf-8').splitlines(keepends=True)

start_pat = re.compile(r'^\s*function\b')
open_pat = re.compile(r'^\s*(if|for|while|switch|try|parfor|spmd|function)\b')
end_pat = re.compile(r'^\s*end\b')

main = []
func_blocks = []
i = 0
n = len(lines)

while i < n:
    line = lines[i]
    if start_pat.match(line):
        block = [line]
        depth = 1
        i += 1
        while i < n and depth > 0:
            l = lines[i]
            s = l.strip()
            if open_pat.match(l):
                depth += 1
            if end_pat.match(l):
                depth -= 1
            block.append(l)
            i += 1
        func_blocks.append(''.join(block))
    else:
        main.append(line)
        i += 1

out = ''.join(main)
if not out.endswith('\n'):
    out += '\n'
out += '\n'
out += '\n'.join(func_blocks)
outfile.write_text(out, encoding='utf-8')
print(f'Wrote {outfile}')
