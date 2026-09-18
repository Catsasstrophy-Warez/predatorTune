#!/usr/bin/env python3
from pathlib import Path
import re, sys
root=Path(__file__).resolve().parents[1]
yml=(root/'project.yml').read_text()
required=['PredatorLab/PredatorLabTests','PredatorLabTests','PredatorLabUITests']
missing=[p for p in required if f'- path: {p}' not in yml]
if missing: sys.exit('ERROR: test source roots absent from project.yml: '+', '.join(missing))
# Catch accidental orphan XCTest files outside admitted test roots.
allowed=[root/p for p in required]
orphans=[]
for p in root.rglob('*.swift'):
    try: text=p.read_text(errors='ignore')
    except OSError: continue
    if ('XCTestCase' in text or 'import XCTest' in text) and not any(a in p.parents or p==a for a in allowed):
        orphans.append(str(p.relative_to(root)))
if orphans: sys.exit('ERROR: XCTest source outside declared test roots: '+', '.join(orphans))
print('Test topology: PASS')
