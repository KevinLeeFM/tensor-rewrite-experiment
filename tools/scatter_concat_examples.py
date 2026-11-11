"""Independent coordinate-table oracle for actual leading-axis input concatenation."""
from itertools import product
from math import prod


def coordinates(shape):
    return list(product(*(range(n) for n in shape)))


def expected():
    counts,events,values=[],[],[]
    geometries=[([n],[w],[0]) for n in range(3) for w in range(3)]
    geometries += [([2,2],[w,w],[1,0]) for w in (1,2)] + [([],[],[])]
    for operand,window,axes in geometries:
        outputs=coordinates(operand);positions={index:i for i,index in enumerate(outputs)}
        windows=coordinates(window)
        for first,second in product(range(3),repeat=2):
            for tail in ([],[0],[2],[2,0],[2,2]):
                profile=len(counts)
                counts.append(dict(profile=profile,operand=operand,window=window,axes=axes,
                                   first=first,second=second,tail=tail,
                                   events=(first+second)*prod(tail)*prod(window)))
                tables=[]
                for count,side in ((first,0),(second,1)):
                    indices={};updates={}
                    for linear,batch in enumerate(coordinates([count]+tail)):
                        indices[batch]=[(linear+2*side+component)%5-2
                                        for component in range(len(axes))]
                        updates[batch]=[1+13*side+10*linear+w for w in range(len(windows))]
                    tables.append((indices,updates))
                # Construct dense concatenated input tensors by the batch coordinate.
                joined_i={};joined_u={}
                for batch in coordinates([first+second]+tail):
                    side=0 if batch[0]<first else 1
                    local=((batch[0] if side==0 else batch[0]-first),)+batch[1:]
                    joined_i[batch]=tables[side][0][local]
                    joined_u[batch]=tables[side][1][local]

                def scatter(index_table,update_table,base,operation,record=False):
                    output=base[:];event_ordinal=0
                    for batch,vector in index_table.items():
                        start=[0]*len(operand)
                        for axis,value in zip(axes,vector):start[axis]=value
                        for ordinal,coordinate in enumerate(windows):
                            address=tuple(a+b for a,b in zip(start,coordinate))
                            target=positions.get(address,-1)
                            value=update_table[batch][ordinal]
                            if record:
                                events.append(dict(profile=profile,event=event_ordinal,target=target,value=value))
                                event_ordinal+=1
                            if target!=-1:output[target]=operation(output[target],value)
                    return output
                base=[i+2 for i in range(len(outputs))]
                other=[3*i+1 for i in range(len(outputs))]
                decimal=scatter(joined_i,joined_u,base,lambda a,b:10*a+b,True)
                nested=scatter(*tables[1],scatter(*tables[0],base,lambda a,b:10*a+b),
                               lambda a,b:10*a+b)
                left=scatter(*tables[0],base,lambda a,b:a+b)
                right=scatter(*tables[1],other,lambda a,b:a+b)
                target=scatter(joined_i,joined_u,[a+b for a,b in zip(base,other)],lambda a,b:a+b)
                for output in range(len(outputs)):
                    source=left[output]+right[output]
                    values.append(dict(profile=profile,output=output,decimal=decimal[output],
                        nested=nested[output],source=source,target=target[output],
                        word_source=source%16,word_target=target[output]%16))
    return counts,events,values
