#!/usr/bin/env python3
"""Bounded experimental HPL waveform probe. No VIN/AES extraction. No universal format claims."""
import argparse, csv, hashlib, math, struct
from pathlib import Path

def sha256(p):
    h=hashlib.sha256()
    with open(p,'rb') as f:
        for b in iter(lambda:f.read(1024*1024),b''): h.update(b)
    return h.hexdigest()

def read_hpt_csv(path):
    lines=Path(path).read_text(errors='replace').splitlines()
    i=lines.index('[Channel Data]')
    ids=next(csv.reader([lines[lines.index('[Channel Information]')+1]]))
    labels=next(csv.reader([lines[lines.index('[Channel Information]')+2]]))
    units=next(csv.reader([lines[lines.index('[Channel Information]')+3]]))
    rows=list(csv.reader(lines[i+1:]))
    return ids,labels,units,rows

def printable_descriptors(data,limit=32768,minlen=8):
    b=data[:limit]; out=[]; i=0
    while i<len(b):
        if 32<=b[i]<=126:
            j=i
            while j<len(b) and 32<=b[j]<=126: j+=1
            if j-i>=minlen: out.append((i,b[i:j].decode('ascii','replace')))
            i=j
        else:i+=1
    return out

def exact_value_hits(data, values):
    hits=[]
    for v in values:
        for enc,fmt in [('f32le','<f'),('f64le','<d')]:
            pat=struct.pack(fmt,float(v)); pos=data.find(pat)
            if pos>=0: hits.append((v,enc,pos))
        iv=int(round(float(v)))
        if 0<=iv<=65535:
            pos=data.find(struct.pack('<H',iv))
            if pos>=0:hits.append((v,'u16le-rounded',pos))
    return hits

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('hpl'); ap.add_argument('csv'); ap.add_argument('--signal',default='Engine RPM (SAE)'); ap.add_argument('--samples',type=int,default=64); a=ap.parse_args()
    data=Path(a.hpl).read_bytes(); ids,labels,units,rows=read_hpt_csv(a.csv)
    if a.signal not in labels: raise SystemExit('signal not found in CSV')
    idx=labels.index(a.signal); vals=[]
    for r in rows:
        if len(r)>idx:
            try: vals.append(float(r[idx]))
            except: pass
        if len(vals)>=a.samples: break
    print('HPL_SHA256',sha256(a.hpl)); print('CSV_SHA256',sha256(a.csv)); print('HPL_PREFIX',data[:32].hex(' '))
    desc=printable_descriptors(data); print('DESCRIPTORS',len(desc));
    for off,text in desc:
        if a.signal.lower().split(' (')[0] in text.lower(): print('SIGNAL_DESCRIPTOR',off,text)
    hits=exact_value_hits(data,vals)
    print('DIRECT_VALUE_HITS',len(hits));
    for h in hits[:50]: print(*h)
    print('NOTE Direct isolated hits are candidates only. Strong admission requires sequence/timing/XML/unit agreement in PredatorLab.')
if __name__=='__main__': main()
