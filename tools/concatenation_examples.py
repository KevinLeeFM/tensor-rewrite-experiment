"""Independent materialized multidimensional arrays; no calls to the Lean segment evaluator."""
from itertools import product


def count_cases():
    return [list(counts) for length in range(4) for counts in product(range(3),repeat=length)]+[[0,1,0,2],[1,2,1,2]]


def csv(values):return ','.join(map(str,values)) if values else '-'


def array(shape,axis,ordinal,word):
    result={}
    for index in product(*(range(extent) for extent in shape)):
        value=200*ordinal+10*index[axis]+sum((a+1)*coordinate for a,coordinate in enumerate(index) if a!=axis)-17
        result[index]=value%256 if word else value
    return result


def materialize(rank,axis,other,counts,word):
    inputs=[];result={};offset=0
    for ordinal,extent in enumerate(counts):
        shape=[other]*rank;shape[axis]=extent
        values=array(shape,axis,ordinal,word);inputs.append(values)
        for index,value in values.items():
            target=list(index);target[axis]+=offset
            result[tuple(target)]=value
        offset+=extent
    return inputs,result


def expected_lines():
    lines=[]
    for rank in [1,2,3]:
        for track in ['integer','word8']:
            for axis,other in product(range(rank),range(3)):
                for counts in count_cases():
                    inputs,whole=materialize(rank,axis,other,counts,track=='word8')
                    shape=[other]*rank;shape[axis]=sum(counts)
                    kept=[extent for extent,values in zip(counts,inputs) if values]
                    context=f'track={track} rank={rank} axis={axis} other={other} counts={csv(counts)}'
                    lines.append(f'CAT_PROFILE {context} shape={csv(shape)} kept={csv(kept)} kept_total={sum(kept)}')
                    for index in product(*(range(extent) for extent in shape)):
                        value=whole[index]
                        lines.append(f'CAT_VALUE {context} index={csv(index)} source={value} zero={value} nested={value} filtered={value}')
                    selected=counts[1:3];middle=sum(selected);offset=sum(counts[:1])
                    for variant,start in enumerate([0,min(1,middle),middle]):
                        length=middle-start;crop_shape=[other]*rank;crop_shape[axis]=length
                        for index in product(*(range(extent) for extent in crop_shape)):
                            original=list(index);original[axis]+=offset+start
                            value=whole[tuple(original)]
                            lines.append(f'CAT_SLICE {context} variant={variant} start={start} length={length} index={csv(index)} source={value} target={value}')
    for bits in [0,0x80000000,0x7fc01234,0x7f801234,0x7f800000,0xff800000]:
        lines.append(f'CAT_FLOAT input={bits} output={bits}')
    return lines
