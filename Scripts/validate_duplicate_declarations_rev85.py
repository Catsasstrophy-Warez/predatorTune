#!/usr/bin/env python3
"""Reject duplicate top-level Swift declarations within each Xcode target source set.
Tracks brace depth so nested Kind/State/etc. declarations do not become false positives.
Extensions are excluded: multiple extensions of one type are legal; member conflicts belong to swiftc/Xcode.
"""
from pathlib import Path
import re, sys
ROOT=Path(__file__).resolve().parent.parent
# NOTE: 'PredatorLab' mirrors project.yml's `sources: [{path: PredatorLab, excludes: [...]}]`
# by walking the whole PredatorLab/ directory rather than an explicit subfolder list, so a
# newly added subfolder (e.g. DesignSystem) can never silently fall outside this check again.
TARGETS={
 'PredatorLab':['PredatorLab'],
 'PredatorLabTests':['PredatorLabTests'],
 'PredatorLabUITests':['PredatorLabUITests'],
}
# Paths (relative to ROOT) excluded from the 'PredatorLab' target, matching project.yml.
EXCLUDES={
 'PredatorLab': [Path('PredatorLab/Info.plist'), Path('PredatorLab/PredatorLabTests')],
}
DECL=re.compile(r'^\s*(?:(?:public|internal|private|fileprivate|open|package|nonisolated)\s+)*(?:(?:final|indirect)\s+)?(struct|class|actor|enum|protocol|typealias)\s+([A-Za-z_][A-Za-z0-9_]*)\b')

def swift_files(entries, excludes=()):
 def is_excluded(p):
  return any(p==ex or ex in p.parents for ex in excludes)
 for e in entries:
  p=ROOT/e
  if p.is_file() and p.suffix=='.swift':
   if not is_excluded(p): yield p
  elif p.is_dir():
   for f in p.rglob('*.swift'):
    if not is_excluded(f): yield f

def top_decls(path):
 depth=0
 in_block=False
 for lineno,line in enumerate(path.read_text(errors='ignore').splitlines(),1):
  # Strip basic comments/strings enough for declaration + brace-depth hygiene. Xcode remains authority.
  code=line
  if in_block:
   if '*/' in code: code=code.split('*/',1)[1]; in_block=False
   else: continue
  if '/*' in code:
   pre,post=code.split('/*',1); code=pre
   if '*/' not in post: in_block=True
  code=code.split('//',1)[0]
  if depth==0:
   m=DECL.match(code)
   if m: yield m.group(2),m.group(1),lineno
  # crude string removal prevents most braces inside literals from perturbing depth
  scrub=re.sub(r'"(?:\\.|[^"\\])*"','""',code)
  depth += scrub.count('{')-scrub.count('}')
  depth=max(depth,0)

bad=False
for target,entries in TARGETS.items():
 found={}
 for f in swift_files(entries, EXCLUDES.get(target, ())):
  for name,kind,line in top_decls(f): found.setdefault(name,[]).append((f.relative_to(ROOT),kind,line))
 dup={k:v for k,v in found.items() if len(v)>1}
 if dup:
  bad=True; print(f'ERROR: duplicate top-level Swift declarations in target {target}:')
  for name,locs in sorted(dup.items()):
   print(' ',name)
   for f,k,l in locs: print(f'    {k} {f}:{l}')
if bad: sys.exit(1)
print('Rev85 duplicate top-level declaration check: PASS')
