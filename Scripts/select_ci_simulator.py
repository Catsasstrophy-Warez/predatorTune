#!/usr/bin/env python3
"""Choose an available iPhone or iPad simulator without assuming a fixed Xcode runtime."""
import argparse,json,subprocess,sys,re
ap=argparse.ArgumentParser(); ap.add_argument('--family',choices=['iphone','ipad'],default='iphone'); args=ap.parse_args()
raw=subprocess.check_output(['xcrun','simctl','list','devices','available','-j'],text=True)
data=json.loads(raw)
prefix='iPhone' if args.family=='iphone' else 'iPad'
preferred={
'iphone':['iPhone 17 Pro Max','iPhone 17 Pro','iPhone 17','iPhone 16 Pro Max','iPhone 16 Pro','iPhone 16'],
'ipad':['iPad Pro 13-inch (M5)','iPad Pro 13-inch (M4)','iPad Pro 11-inch (M5)','iPad Pro 11-inch (M4)','iPad Air 13-inch (M3)','iPad Air 11-inch (M3)']
}[args.family]
def runtime_key(s):
    nums=[int(x) for x in re.findall(r'\d+',s)]
    return tuple(nums)
devices=[]
for runtime,items in data.get('devices',{}).items():
    if 'iOS' not in runtime: continue
    for d in items:
        if d.get('isAvailable') and d.get('name','').startswith(prefix): devices.append((runtime_key(runtime),d))
if not devices: sys.exit(f'No available {prefix} simulator runtime found')
devices.sort(key=lambda x:x[0], reverse=True)
for name in preferred:
    for _,d in devices:
        if d['name']==name: print(d['udid']); sys.exit(0)
print(devices[0][1]['udid'])
