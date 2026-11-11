"""Independent coordinate-table oracle for raw update-axis partitions and singleton insertion."""
from itertools import product


def coordinates(shape):return list(product(*(range(n) for n in shape)))


def specifications():
    for n,w,b in product(range(3),repeat=3):
        yield [n],[b,w],[0,1],[0],[0]
        yield [n],[w,b],[1,0],[0],[0]
        yield [2,n],[w,b],[1,0],[1,0],[1,0]
        yield [n,2],[b,w],[0,1],[0,1],[0]
    for b0,b1,w0,w1 in product(range(3),repeat=4):
        yield [2,2,2],[b0,w0,b1,w1],[0,1,0,1],[0,1,0],[2,0]
    for b in range(4):
        yield [],[b],[0],[],[]
        yield [2,2],[b],[0],[1,1],[1,0]


def expected():
    counts,events,values=[],[],[]
    for profile,(operand,raw,mask,insert,axes) in enumerate(specifications()):
        batch=[n for n,m in zip(raw,mask) if m==0]
        compact=[n for n,m in zip(raw,mask) if m==1]
        sizes=iter(compact);full=[1 if m else next(sizes) for m in insert]
        outputs=coordinates(operand);positions={p:i for i,p in enumerate(outputs)}
        raw_positions={p:i for i,p in enumerate(coordinates(raw))}
        batches=coordinates(batch);batch_positions={p:i for i,p in enumerate(batches)}

        def event(batch_index,window,raw_index):
            compact_iter=iter(window);offset=[0 if m else next(compact_iter) for m in insert]
            for component,axis in enumerate(axes):
                offset[axis]+=(batch_positions[batch_index]+component)%4-1
            return positions.get(tuple(offset),-1),raw_positions[raw_index]+1

        ordered=[]
        for batch_index in batches:
            for window in coordinates(compact):
                batch_iter=iter(batch_index);window_iter=iter(window)
                raw_index=tuple(next(window_iter) if m else next(batch_iter) for m in mask)
                ordered.append(event(batch_index,window,raw_index))
        storage=[]
        for raw_index in coordinates(raw):
            batch_index=tuple(x for x,m in zip(raw_index,mask) if m==0)
            window=tuple(x for x,m in zip(raw_index,mask) if m==1)
            storage.append(event(batch_index,window,raw_index))
        counts.append(dict(profile=profile,operand=operand,raw=raw,batch=batch,compact=compact,
                           full=full,update_mask=mask,insert_mask=insert,axes=axes,events=len(ordered)))
        for ordinal,(target,value) in enumerate(ordered):
            events.append(dict(profile=profile,event=ordinal,target=target,value=value))
        base=[i+2 for i in range(len(outputs))]
        separate=[3*i+1 for i in range(len(outputs))]
        decimal=base[:];raw_result=base[:];sum_result=base[:]
        coupled=[[value,-value] for value in base]
        for target,value in ordered:
            if target!=-1:
                decimal[target]=10*decimal[target]+value
                sum_result[target]+=value
                first,second=coupled[target]
                coupled[target]=[first+1-value,first+second-value]
        for target,value in storage:
            if target!=-1:raw_result[target]=10*raw_result[target]+value
        for output in range(len(outputs)):
            combined=separate[output]+sum_result[output]
            values.append(dict(profile=profile,output=output,decimal=decimal[output],
                canonical=decimal[output],storage=raw_result[output],source=combined,target=combined,
                word_source=combined%16,word_target=combined%16,coupled=coupled[output],
                coupled_canonical=coupled[output]))
    return counts,events,values
