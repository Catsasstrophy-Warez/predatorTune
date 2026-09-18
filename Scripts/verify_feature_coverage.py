#!/usr/bin/env python3
import json, pathlib, sys
root=pathlib.Path(__file__).resolve().parents[1]
p=root/'Audit/FEATURE-COVERAGE-REGISTRY.json'
data=json.loads(p.read_text())
ids=[]
for f in data.get('features',[]):
    for k in ('id','lifecycle','sourceOwner','tests','platforms','authority','knownLimitations'):
        if k not in f: raise SystemExit(f'ERROR: feature {f.get("id")} missing {k}')
    ids.append(f['id'])
if len(ids)!=len(set(ids)): raise SystemExit('ERROR: duplicate feature IDs')
print(f'Feature coverage registry: PASS ({len(ids)} features)')
