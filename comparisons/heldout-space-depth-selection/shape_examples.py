"""Finite diagnostic of the source's local guards and logical array maps; not XLA execution."""
from itertools import product
from math import prod
import json, time
from pathlib import Path

def branch(x, inner, perm, outer):
    n=len(x)
    if len(inner)!=n+1 or len(perm)!=n+1 or sorted(perm)!=list(range(n+1)) or len(outer)<n: return False
    first=next((i for i in range(n) if inner[i]!=x[i]),None)
    if first is None or x[first]!=inner[first]*inner[first+1]: return False
    if any(inner[i+1]!=x[i] for i in range(first+1,n)): return False
    k=inner[first];t=perm.index(first)
    if k>5 or t in (first,first+1): return False
    if any(perm[d]!=d-int(d>t)+int(d>first) for d in range(n+1) if d!=t): return False
    # Division by zero is recorded as undefined here, not treated as an LLVM/Python identity.
    for d in range(n):
        if d==t-1: expected=x[d]*k
        elif d==first:
            if k==0: return 'division-by-zero'
            expected=x[d]//k
        else: expected=x[d]
        if outer[d]!=expected: return False
    return True

def ix(shape): return product(*(range(n) for n in shape))
def lin(shape,idx):
    v=0
    for d,i in zip(shape,idx):v=v*d+i
    return v

def transpose_flat(inner,perm):
    out=[inner[i] for i in perm]
    for j in ix(out):
        src=[0]*len(inner)
        for d,srcd in enumerate(perm):src[srcd]=j[d]
        yield lin(inner,src)

def slice_concat_flat(x,split,k,axis):
    chunk=x[split]//k
    shape=list(x);shape[split]=chunk;shape[axis]*=k
    for i in ix(shape):
        src=list(i);which,src[axis]=divmod(i[axis],x[axis]);src[split]+=which*chunk
        yield lin(x,src)

cases={
 'valid_nonempty':([3,4,6],[3,4,2,3],[0,2,1,3],[6,4,3],True),
 'valid_retained_zero':([0,4,6],[0,4,2,3],[0,2,1,3],[0,4,3],True),
 'valid_one_chunk':([3,4,3],[3,4,1,3],[0,2,1,3],[3,4,3],True),
 'invalid_permutation':([6,4],[2,3,4],[1,2,0],[3,8],False),
 'invalid_outer_shape':([3,4,6],[3,4,2,3],[0,2,1,3],[3,4,6],False),
 'invalid_split_product':([3,4,6],[2,6,2,3],[0,2,1,3],[6,4,3],False),
}
t=time.monotonic();results={}
for name,(x,inner,perm,outer,expected) in cases.items():
 got=branch(x,inner,perm,outer);assert got==expected,(name,got)
 assert prod(x)==prod(inner)==prod(outer)
 results[name]={'guard':got,'input':x,'inner':inner,'perm':perm,'outer':outer}
x,inner,perm,outer,_=cases['valid_nonempty'];lhs=list(transpose_flat(inner,perm));rhs=list(slice_concat_flat(x,2,2,1));wrong=list(slice_concat_flat(x,2,2,0));assert lhs==rhs and lhs!=wrong
first=next(i for i,(a,b) in enumerate(zip(lhs,wrong)) if a!=b)
results['observations']={'valid_elements':len(lhs),'correct_mismatches':sum(a!=b for a,b in zip(lhs,rhs)),'wrong_axis_first_mismatch_flat_index':first,'original_value':lhs[first],'wrong_value':wrong[first]}
x,inner,perm,outer,_=cases['valid_retained_zero'];assert list(transpose_flat(inner,perm))==[] and list(slice_concat_flat(x,2,2,1))==[]
results['seconds']=time.monotonic()-t
p=Path(__file__).parent;(p/'shape-examples.json').write_text(json.dumps(results,indent=2)+'\n');print(json.dumps(results,indent=2))
