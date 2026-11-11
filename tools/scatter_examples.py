"""Independent dense-table Scatter evaluator and original ordered address generation."""
from itertools import product
from math import prod
from ordered_float_examples import add


def coordinates(shape): return list(product(*(range(n) for n in shape)))


def start(mode,batch,component):
    return ((-2,-1,0,1,3)[mode] if mode<5 else
            batch-1 if mode==5 else 1-batch if mode==6 else 2*(batch%2)-1)+component


def profiles():
    out=[]
    for extent in range(4):
        for window in range(4):
            for batches in range(4):
                for mode in range(8):out.append(([extent],[batches],[window],[0],mode,False))
    for n0 in range(3):
        for n1 in range(3):
            for w0 in range(3):
                for w1 in range(3):
                    for batches in range(3):
                        for mode in (2,5,7):
                            for axes in ([0],[1],[1,0]):
                                out.append(([n0,n1],[batches],[w0,w1],axes,mode,False))
    out.extend(([],[b],[],[],2,False) for b in range(4))
    out.extend((shape,[],shape,[],2,True) for shape in ([],[0],[1],[3],[2,2],[0,2]))
    return out


def events(operand,batch,window,axes,mode,right=False):
    targets=coordinates(operand);position={p:i for i,p in enumerate(targets)};result=[]
    for ordinal,_ in enumerate(coordinates(batch)):
        offsets={axis:start(mode,ordinal,c)+(1 if right else 0) for c,axis in enumerate(axes)}
        for offset,point in enumerate(coordinates(window)):
            target=tuple(offsets.get(axis,0)+value for axis,value in enumerate(point))
            value=ordinal*prod(window)+offset+1
            if right:value=2*value+1
            result.append((position.get(target,-1),value))
    return result


def execute(base,events,operation):
    # Dense table updates are independent of the Lean filtered-coordinate fold theorem.
    state=list(base)
    for target,value in events:
        if target>=0:state[target]=operation(state[target],value)
    return state


def expected():
    counts,entry_rows,rows,roles,floats=[],[],[],[],[]
    for profile,(operand,batch,window,axes,mode,is_map) in enumerate(profiles()):
        left=events(operand,batch,window,axes,mode);right=events(operand,batch,window,axes,mode,True)
        size=prod(operand);base=[i+2 for i in range(size)];separate=[3*i+1 for i in range(size)]
        decimal=execute(base,left,lambda a,b:10*a+b)
        reverse=execute(base,left[::-1],lambda a,b:10*a+b)
        added=execute(base,left,lambda a,b:a+b)
        combined_base=[a+b for a,b in zip(base,separate)]
        translated=execute(combined_base,left,lambda a,b:a+b)
        second=execute(separate,right,lambda a,b:a+b)
        concatenated=execute(combined_base,left+right,lambda a,b:a+b)
        nested=execute(execute(combined_base,left,lambda a,b:a+b),right,lambda a,b:a+b)
        coupled=[(value,-value) for value in base]
        for target,value in left:
            if target>=0:
                a,b=coupled[target];coupled[target]=(a+1-value,a+b-value)
        counts.append(dict(profile=profile,mode=mode,operand=operand,batch=batch,window=window,
                           axes=axes,events=len(left),outputs=size,map_case=is_map))
        entry_rows.extend(dict(profile=profile,event=n,target=t,value=v) for n,(t,v) in enumerate(left))
        for output in range(size):
            rows.append(dict(profile=profile,output=output,trace=[v for t,v in left if t==output],
                             decimal=decimal[output],reverse=reverse[output],
                             translation_source=separate[output]+added[output],
                             translation_target=translated[output],pair_source=added[output]+second[output],
                             concatenated=concatenated[output],nested=nested[output],
                             coupled=list(coupled[output]),
                             map_expected=10*base[output]+output+1 if is_map else -1))
            for first in ('current','update'):
                for second_role in ('current','update'):
                    def reducer(old,new):
                        return ((old if first=='current' else new)+
                                (old if second_role=='current' else new))%16
                    word_base=[x%16 for x in base];word_separate=[x%16 for x in separate]
                    word_events=[(t,v%16) for t,v in left]
                    old=execute(word_base,word_events,reducer)
                    new=execute([(a+b)%16 for a,b in zip(word_base,word_separate)],word_events,reducer)
                    roles.append(dict(profile=profile,output=output,first=first,second=second_role,
                                      source=(word_separate[output]+old[output])%16,target=new[output]))
    for base,separate,update in ((0x4b800000,0xcb800000,0x3f800000),
                                 (0x3f800000,0x40000000,0x40400000),(0,0x80000000,0x80000000),(1,2,3)):
        floats.append(dict(base=base,separate=separate,update=update,
                           source=add(separate,add(base,update)),target=add(add(separate,base),update)))
    return counts,entry_rows,rows,roles,floats
