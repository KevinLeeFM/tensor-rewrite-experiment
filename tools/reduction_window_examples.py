"""Independent window oracle: occupied-coordinate tables and containment enumeration."""
from itertools import product
from math import prod


def axis(n,k,s=1,b=1,d=1,lo=0,hi=0,rev=False):
    return dict(n=n,k=k,s=s,b=b,d=d,lo=lo,hi=hi,rev=rev)


PROFILES=[
    ('scalar',[]),
    ('pointwise',[axis(3,1,d=7,rev=True)]),
    ('unit_padding',[axis(2,1,lo=1,hi=2)]),
    ('unit_crop',[axis(4,1,lo=-1,hi=-1)]),
    ('unit_stride',[axis(5,1,s=2,lo=1)]),
    ('base_holes',[axis(3,1,b=2)]),
    ('kernel_dilation',[axis(6,3,d=2,lo=1,hi=1)]),
    ('kernel_reversal',[axis(3,3,rev=True)]),
    ('empty_input',[axis(0,2,lo=2,hi=2)]),
    ('empty_kernel',[axis(2,0)]),
    ('empty_output',[axis(2,5)]),
    ('mixed_unit',[axis(2,1,lo=1),axis(3,1,lo=-1)]),
    ('crop_all_low',[axis(2,1,lo=-2,hi=3)]),
    ('crop_all_high',[axis(2,1,lo=3,hi=-2)]),
    ('mixed_kernel',[axis(2,2),axis(3,2,lo=1)]),
]


def extent(a):
    input_span=0 if not a['n'] else (a['n']-1)*a['b']+1
    kernel_span=0 if not a['k'] else (a['k']-1)*a['d']+1
    padded=a['lo']+input_span+a['hi']
    return sum(o*a['s']+kernel_span<=padded for o in range(max(padded+1,0)))


def input_value(index,axes):
    value=0
    for i,a in zip(index,axes):value=value*a['n']+i
    return value+1


def expected():
    counts=[];rows=[]
    for name,axes in PROFILES:
        outputs=list(product(*(range(extent(a)) for a in axes)))
        kernels=list(product(*(range(a['k']) for a in axes)))
        eligible=all(a['k']==1 and a['b']==1 for a in axes)
        counts.append(dict(name=name,outputs=len(outputs),window=len(kernels),unit_affine=eligible))
        occupied=[{i*a['b']:i for i in range(a['n'])} for a in axes]
        for position,output in enumerate(outputs):
            trace=[]
            for kernel in kernels:
                sampled=[]
                for a,o,k,table in zip(axes,output,kernel,occupied):
                    k=a['k']-1-k if a['rev'] else k
                    sampled.append(table.get(o*a['s']+k*a['d']-a['lo']))
                trace.append(0 if None in sampled else input_value(sampled,axes))
            values=[v or 3 for v in trace]
            decimal=0
            for v in trace:decimal=10*decimal+v
            gathered=[o*a['s']-a['lo'] for a,o in zip(axes,output)]
            valid=all(0<=i<a['n'] for a,i in zip(axes,gathered))
            gather=input_value(gathered,axes) if valid else 0
            rows.append(dict(name=name,output=position,trace=trace,sum=7+sum(values),
                             zero=sum(trace),decimal=decimal,min=min([5]+[v or 5 for v in trace]),
                             max=max([5]+[v or 5 for v in trace]),gather=gather))
    return counts,rows
