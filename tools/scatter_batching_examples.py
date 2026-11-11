"""Independent coordinate-table semantics for actual paired operand/index batch dimensions."""
from itertools import product


def coordinates(shape):return list(product(*(range(n) for n in shape)))


def specifications():
    for b,n,w in product(range(3),repeat=3):
        for reverse in (False,True):
            raw,mask=([w,b],[1,0]) if reverse else ([b,w],[0,1])
            for axis in (0,1,-1):yield 1,[b,n],raw,mask,[1,0],[1],[0],[0],axis
            for axis in (0,1):yield 0,[b,n],raw,mask,[1,0],[],[0],[0],axis
    for b0,b1,n,w in product(range(3),repeat=4):
        for mode in range(3):
            operand=[b1,b0,n] if mode==1 else [b0,b1,n]
            op=[0,1] if mode==0 else [1,0]
            ix=[1,0] if mode==2 else [0,1]
            for axis in (0,1,2,-1):
                yield 1,operand,[b0,w,b1],[0,1,0],[1,1,0],[2],op,ix,axis
        for selected in range(2):
            for axis in (0,1,2,-1):
                yield 1,[[b0,b1][selected],n],[b0,w,b1],[0,1,0],[1,0],[1],[0],[selected],axis
    for b0,b1 in product(range(3),repeat=2):
        for reverse in (False,True):
            operand=[b1,b0] if reverse else [b0,b1]
            for axis in (0,2):
                yield 0,operand,[b0,b1],[0,0],[1,1],[],[1,0] if reverse else [0,1],[0,1],axis
    for n,w,b in product(range(3),repeat=3):
        for axis in (0,-1):yield 1,[n],[b,w],[0,1],[0],[0],[],[],axis
    yield 0,[],[],[],[],[],[],[],0
    for n,w,b in product(range(3),repeat=3):
        for axis in (0,1):yield 2,[b,n,n],[b,w,w],[0,1,1],[1,0,0],[2,1],[0],[0],axis


def expected():
    counts,events,values=[],[],[]
    for profile,(components,operand,raw,mask,insert,index_axes,op_pairs,ix_pairs,axis) in enumerate(specifications()):
        batch=[n for n,m in zip(raw,mask) if m==0];compact=[n for n,m in zip(raw,mask) if m==1]
        sizes=iter(compact);full=[1 if m else next(sizes) for m in insert]
        shape=batch[:] if axis==-1 else batch[:axis]+[components]+batch[axis:]
        index_table={p:i%4-1 for i,p in enumerate(coordinates(shape))}
        updates={p:i+1 for i,p in enumerate(coordinates(raw))}
        positions={p:i for i,p in enumerate(coordinates(operand))}
        assert len(set(op_pairs))==len(op_pairs)==len(set(ix_pairs))
        assert not set(op_pairs)&set(index_axes)
        assert all(operand[o]==batch[i] and insert[o]==1 for o,i in zip(op_pairs,ix_pairs))
        traces=[[],[],[]]  # actual original, batching ignored, actual right-hand input
        for coordinate in coordinates(batch):
            vector=[]
            for component in range(components):
                raw_index=coordinate if axis==-1 else coordinate[:axis]+(component,)+coordinate[axis:]
                vector.append(index_table[raw_index])
            for window in coordinates(compact):
                window_iter=iter(window);window_full=[0 if m else next(window_iter) for m in insert]
                batch_iter=iter(coordinate);window_iter=iter(window)
                raw_update=tuple(next(window_iter) if m else next(batch_iter) for m in mask)
                value=updates[raw_update]
                for which in range(3):
                    target=window_full[:]
                    for dimension,start in zip(index_axes,vector):target[dimension]+=start+(which==2)
                    if which!=1:
                        for dimension,batch_axis in zip(op_pairs,ix_pairs):target[dimension]=coordinate[batch_axis]
                    traces[which].append((positions.get(tuple(target),-1),2*value+1 if which==2 else value))
        raw_pairs=[i if axis==-1 or i<axis else i+1 for i in ix_pairs]
        counts.append(dict(profile=profile,components=components,operand=operand,index_raw=shape,
            vector_axis=axis,update_raw=raw,batch=batch,compact=compact,full=full,index_axes=index_axes,
            operand_pairs=op_pairs,index_pairs=ix_pairs,raw_index_pairs=raw_pairs,events=len(traces[0])))
        for ordinal,(target,value) in enumerate(traces[0]):
            events.append(dict(profile=profile,event=ordinal,target=target,value=value))
        base=[i+2 for i in range(len(positions))];separate=[3*i+1 for i in range(len(positions))]
        def execute(trace,initial,operation):
            result=initial[:]
            for target,value in trace:
                if target!=-1:result[target]=operation(result[target],value)
            return result
        decimal=execute(traces[0],base,lambda a,b:10*a+b)
        ignored=execute(traces[1],base,lambda a,b:10*a+b)
        left=execute(traces[0],[a%16 for a in base],lambda a,b:(a+b)%16)
        right=execute(traces[2],[a%16 for a in separate],lambda a,b:(a+b)%16)
        combined=[(a+b)%16 for a,b in zip(base,separate)]
        translation=execute(traces[0],combined,lambda a,b:(a+b)%16)
        nested=execute(traces[2],translation,lambda a,b:(a+b)%16)
        for output in range(len(positions)):
            values.append(dict(profile=profile,output=output,decimal=decimal[output],
                canonical=decimal[output],ignored=ignored[output],moved=decimal[output],
                translated=(left[output]+separate[output])%16,translation_target=translation[output],
                pair=(left[output]+right[output])%16,nested=nested[output]))
    return counts,events,values
