#!/usr/bin/env python3
from pathlib import Path
import sys, re
root=Path(__file__).resolve().parents[1]
yml=(root/'project.yml').read_text()
required=['PredatorLab/Resources/Fixtures','PredatorLab/Resources/ImportedHPL']
missing=[p for p in required if p not in yml]
if missing:
    sys.exit('ERROR: resource roots absent from project.yml: '+', '.join(missing))
for p in required:
    if not (root/p).is_dir(): sys.exit(f'ERROR: resource directory missing: {p}')
# Golden corpus must exist exactly once to avoid ambiguous copies.
name='sep2_full_real_hptuners_export.csv'
hits=list(root.rglob(name))
if len(hits)!=1: sys.exit(f'ERROR: expected exactly one {name}, found {len(hits)}')
print('Resource topology: PASS')
