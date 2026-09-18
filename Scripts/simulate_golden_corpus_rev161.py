#!/usr/bin/env python3
"""Independent mirror of the admitted Rev131/Rev125 episode rules over the frozen sep2 fixture.
This validates fixture behavior and regression expectations; it does not execute Swift/XCTest.
"""
from pathlib import Path
import csv, statistics, collections, sys
root=Path(__file__).resolve().parents[1]
p=root/'PredatorLab/Resources/Fixtures/sep2_full_real_hptuners_export.csv'
lines=p.read_text(errors='replace').splitlines()
header=next(i for i,l in enumerate(lines) if l.startswith('Offset,'))
data_idx=lines.index('[Channel Data]')+1
reader=csv.DictReader([lines[header]]+lines[data_idx:])
rows=list(reader); names=reader.fieldnames or []
assert len(rows)==26943, len(rows); assert len(names)==61, len(names)
ts=[float(r['Offset']) for r in rows]
assert ts[0]==2.268 and ts[-1]==1122.728
assert abs((ts[-1]-ts[0])-1120.460)<1e-9
assert abs(statistics.median(b-a for a,b in zip(ts,ts[1:]))-0.040)<1e-9
source_names=['Torque Source','Torque Max Source','Torque Max Protection Source','Throttle Angle Source','Spark Source','RPM Limit Source']
marks=[]; previous={}
def num(r,n):
    try:return float(r[n])
    except (ValueError,TypeError,KeyError):return None
for i,r in enumerate(rows):
    t=ts[i]; pedal=num(r,'Accelerator Position D (SAE)'); throttle=num(r,'Throttle Angle')
    if pedal is not None and throttle is not None and pedal>=60 and throttle>=50: marks.append((t,'highDemand'))
    d=num(r,'Throttle Desired Angle'); a=num(r,'Throttle Angle')
    if d is not None and a is not None and abs(d-a)>=5: marks.append((t,'throttleDisagreement'))
    temp=num(r,'Intake Air Temp 2')
    if temp is not None and temp>=115: marks.append((t,'thermalHighContext'))
    if i and (rpm:=num(r,'Engine RPM (SAE)')) is not None and (prior:=num(rows[i-1],'Engine RPM (SAE)')) is not None and rpm-prior>=300: marks.append((t,'acceleration'))
    for n in source_names:
        v=r.get(n,'')
        if v:
            if n in previous and previous[n]!=v: marks.append((t,'sourceActivity'))
            previous[n]=v
by=collections.defaultdict(list)
for t,k in marks:by[k].append(t)
episodes=[]
for kind,times in by.items():
    cluster=[]
    for t in sorted(times):
        if cluster and t-cluster[-1]>0.30:
            episodes.append((kind,cluster[0],cluster[-1],len(cluster))); cluster=[]
        cluster.append(t)
    if cluster:episodes.append((kind,cluster[0],cluster[-1],len(cluster)))
expected_marks={'sourceActivity':2087,'throttleDisagreement':148,'thermalHighContext':2805,'acceleration':3,'highDemand':29}
expected_eps={'sourceActivity':407,'throttleDisagreement':61,'thermalHighContext':5,'acceleration':3,'highDemand':2}
assert {k:len(v) for k,v in by.items()}==expected_marks
assert dict(collections.Counter(k for k,*_ in episodes))==expected_eps
hd=[e for e in episodes if e[0]=='highDemand']
assert hd==[('highDemand',5.578,6.418,21),('highDemand',970.854,971.134,8)],hd
print('Golden Corpus behavioral simulation: PASS')
print(f'rows={len(rows)} cols={len(names)} span={ts[-1]-ts[0]:.3f}s median_row_delta={statistics.median(b-a for a,b in zip(ts,ts[1:])):.3f}s')
print('marks='+str(expected_marks)); print('episodes='+str(expected_eps)); print('highDemand='+str(hd))
print('BOUNDARY: thresholds are analysis/navigation parameters, not Ford WOT/fault/protection definitions; this Python mirror is not Swift runtime proof.')
