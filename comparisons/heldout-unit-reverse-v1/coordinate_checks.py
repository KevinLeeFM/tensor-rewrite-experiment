#!/usr/bin/env python3
"""Small independent row-major/source-remapping sanity check, not native XLA execution."""
from itertools import product, combinations
from math import prod
from pathlib import Path
import json, time

def coords(shape):
    return product(*(range(d) for d in shape))

def linear(shape,index):
    result=0
    for d,i in zip(shape,index):
        result=result*d+i
    return result

t0=time.monotonic(); plans=masks=observations=empty_plans=scalar_plans=0
for n in range(3):
 for shape in product(range(4),repeat=n):
  for extra in range(3):
   m=n+extra
   for kept in combinations(range(m),n):
    plans+=1
    if not n: scalar_plans+=1
    if prod(shape)==0: empty_plans+=1
    inserted=set(range(m))-set(kept)
    out=tuple(shape[kept.index(j)] if j in kept else 1 for j in range(m))
    for bits in product([False,True],repeat=m):
     masks+=1
     # Literal native loop arithmetic, skipping every size-one output axis.
     remapped={d-sum(k<d for k in inserted) for d in range(m) if bits[d] and out[d]!=1}
     # Independent retained-axis pullback used by Spec, including original unit axes.
     expected={i for i,d in enumerate(kept) if bits[d] and shape[i]!=1}
     assert remapped==expected,(shape,out,kept,bits,remapped,expected)
     for index in coords(out):
      observations+=1
      original_index=tuple(d-1-i if flag else i for d,i,flag in zip(out,index,bits))
      lhs=linear(out,original_index) # Reshape reads by unchanged row-major element order.
      source_index=tuple(index[d] for d in kept)
      rhs_index=tuple(d-1-i if j in remapped else i for j,(d,i) in enumerate(zip(shape,source_index)))
      rhs=linear(shape,rhs_index)
      assert lhs==rhs,(shape,out,kept,bits,index,lhs,rhs)
result=dict(plans=plans,axis_masks=masks,observations=observations,empty_plans=empty_plans,
 scalar_plans=scalar_plans,seconds=time.monotonic()-t0,mismatches=0,
 scope='Ranks 0..2, extents 0..3, 0..2 inserted units, all placements/masks/valid coordinates; source transcription sanity check only')
p=Path(__file__).resolve().parent
(p/'coordinate-checks.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
