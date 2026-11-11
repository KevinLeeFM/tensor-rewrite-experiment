"""Independent dense coordinate oracles for raw vector-axis readers and raw-input Scatter."""
from itertools import product


def coordinates(shape):return list(product(*(range(n) for n in shape)))


def raw_shape(components,batch,axis):
    return batch[:] if axis==-1 else batch[:axis]+[components]+batch[axis:]


def raw_coordinate(batch,component,axis):
    return batch if axis==-1 else batch[:axis]+(component,)+batch[axis:]


def reader_specs():
    for components in range(4):
        yield components,[],0,0
        for batch in range(3):
            yield components,[batch],0,1
            yield components,[batch],1,0
        for b0,b1 in product(range(3),repeat=2):
            for axis in (0,1,2):yield components,[b0,b1],axis,0
    yield 1,[],-1,0
    yield 1,[],0,-1
    for batch in range(3):
        yield 1,[batch],-1,0
        yield 1,[batch],0,-1
    for b0,b1 in product(range(3),repeat=2):
        yield 1,[b0,b1],-1,0
        yield 1,[b0,b1],0,-1


def scatter_specs():
    for n,w,b in product(range(3),repeat=3):
        for axis in (0,1,-1):yield 1,[n],[b,w],[0,1],[0],[0],axis
        for axis in (0,1):yield 2,[2,n],[w,b],[1,0],[1,0],[1,0],axis
        for axis in (0,1):yield 0,[n],[b,w],[0,1],[0],[],axis
    for b0,b1,w in product(range(3),repeat=3):
        for axis in (0,1,2,-1):
            yield 1,[2,2,2],[b0,w,b1,w],[0,1,0,1],[0,1,0],[2],axis
    for batch in range(4):
        for axis in (0,1):yield 0,[],[batch],[0],[],[],axis


def expected():
    counts,raws,readers,targets=[],[],[],[]
    for profile,(components,batch,axis,target_axis) in enumerate(reader_specs()):
        shape=raw_shape(components,batch,axis)
        target_shape=raw_shape(components,batch,target_axis)
        positions={p:i for i,p in enumerate(coordinates(shape))}
        table={p:(i*3+7)%17-8 for p,i in positions.items()}
        counts.append(dict(profile=profile,components=components,batch=batch,raw=shape,axis=axis,
                           target_raw=target_shape,target_axis=target_axis))
        for raw,position in positions.items():
            raws.append(dict(profile=profile,position=position,value=table[raw],packed=table[raw]))
        for ordinal,batch_coordinate in enumerate(coordinates(batch)):
            for component in range(components):
                coordinate=raw_coordinate(batch_coordinate,component,axis)
                value=table[coordinate];bits=value%16
                readers.append(dict(profile=profile,batch=ordinal,component=component,
                    coordinate=list(coordinate),position=positions[coordinate],value=value,moved=value,
                    signed=bits if bits<8 else bits-16,unsigned=bits))
        for position,coordinate in enumerate(coordinates(target_shape)):
            if target_axis==-1:batch_coordinate=coordinate;component=0
            else:
                batch_coordinate=coordinate[:target_axis]+coordinate[target_axis+1:]
                component=coordinate[target_axis]
            value=table[raw_coordinate(batch_coordinate,component,axis)]
            targets.append(dict(profile=profile,position=position,value=value))
    scatter_counts,events,values=[],[],[]
    for profile,(components,operand,update_shape,mask,insert,axes,axis) in enumerate(scatter_specs()):
        batch=[n for n,m in zip(update_shape,mask) if m==0]
        compact=[n for n,m in zip(update_shape,mask) if m==1]
        sizes=iter(compact);full=[1 if m else next(sizes) for m in insert]
        index_shape=raw_shape(components,batch,axis)
        index_table={coordinate:i%4-1 for i,coordinate in enumerate(coordinates(index_shape))}
        updates={coordinate:i+1 for i,coordinate in enumerate(coordinates(update_shape))}
        outputs=coordinates(operand);positions={p:i for i,p in enumerate(outputs)}
        trace=[];unsigned_trace=[]
        for batch_coordinate in coordinates(batch):
            vector=[index_table[raw_coordinate(batch_coordinate,c,axis)] for c in range(components)]
            for window in coordinates(compact):
                window_iter=iter(window);offset=[0 if m else next(window_iter) for m in insert]
                signed_address=offset[:];unsigned_address=offset[:]
                for dimension,start in zip(axes,vector):
                    signed_address[dimension]+=start
                    unsigned_address[dimension]+=start%16
                batch_iter=iter(batch_coordinate);window_iter=iter(window)
                update_coordinate=tuple(next(window_iter) if m else next(batch_iter) for m in mask)
                value=updates[update_coordinate]
                trace.append((positions.get(tuple(signed_address),-1),value))
                unsigned_trace.append((positions.get(tuple(unsigned_address),-1),value))
        scatter_counts.append(dict(profile=profile,components=components,index_raw=index_shape,
            index_axis=axis,operand=operand,update_raw=update_shape,batch=batch,compact=compact,
            full=full,axes=axes,events=len(trace)))
        for ordinal,(target,value) in enumerate(trace):
            events.append(dict(profile=profile,event=ordinal,target=target,value=value))
        base=[i+2 for i in range(len(outputs))];decimal=base[:];unsigned=base[:];sums=base[:]
        for target,value in trace:
            if target!=-1:decimal[target]=10*decimal[target]+value;sums[target]+=value
        for target,value in unsigned_trace:
            if target!=-1:unsigned[target]=10*unsigned[target]+value
        for output in range(len(outputs)):
            word=(3*output+1+sums[output])%16
            values.append(dict(profile=profile,output=output,decimal=decimal[output],
                canonical=decimal[output],moved=decimal[output],unsigned=unsigned[output],
                word_source=word,word_target=word))
    return counts,raws,readers,targets,scatter_counts,events,values
