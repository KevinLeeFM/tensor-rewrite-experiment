"""Independent materialized arrays for actual Slice, boundary Pad and singleton expansion."""
from itertools import chain, product

CONFIGS=((0,0,0,0,1),(5,0,2,5,1),(5,1,2,5,2),(5,0,3,5,2),
         (5,1,1,5,3),(5,2,5,5,1),(5,0,0,4,2))
BITS=(0,0x80000000,0x7fc01234,0x7f801234,0x7f800000,0xff800000)


def csv(values):return ','.join(map(str,values)) or '-'
def coordinates(shape):return product(*(range(n) for n in shape))
def encode(value,track):return value if track=='integer' else value%256
def datum(index):return sum((axis+1)*10*p for axis,p in enumerate(index))-17


def materialize(shape,function):return {index:function(index) for index in coordinates(shape)}


def concatenate_arrays(operands,axis,other_shape):
    """Join complete row lists from independently materialized operands."""
    result={}
    rest_shape=list(other_shape);rest_shape[axis]=1
    for rest in coordinates(rest_shape):
        rows=[]
        for shape,array in operands:
            row=[]
            for p in range(shape[axis]):
                index=list(rest);index[axis]=p
                row.append(array[tuple(index)])
            rows.append(row)
        for p,value in enumerate(chain.from_iterable(rows)):
            index=list(rest);index[axis]=p
            result[tuple(index)]=value
    return result


def adjacent_lines(track,rank):
    out=[]
    for axis in range(rank):
        for other in (0,1,2):
            retained=() if other==0 else tuple(range(5)) if other==1 else (1,3)
            for extent,start,middle,stop,stride in CONFIGS:
                first=tuple(range(start,middle,stride));next_start=start+len(first)*stride
                second=tuple(range(next_start,stop,stride))
                assert 0<=start<=middle<=extent and next_start<=stop<=extent
                def operand(points):
                    shape=[len(retained)]*rank;shape[axis]=len(points)
                    def value(index):
                        original=[retained[p] if a!=axis else points[p] for a,p in enumerate(index)]
                        return encode(datum(original),track)
                    return shape,materialize(shape,value)
                def constant(length,value):
                    shape=[len(retained)]*rank;shape[axis]=length
                    return shape,materialize(shape,lambda _:encode(value,track))
                operands=[constant(1,71),operand(first),operand(second),constant(2,93)]
                merged=tuple(range(start,stop,stride))
                targets=[constant(1,71),operand(merged),constant(2,93)]
                shape=[len(retained)]*rank;shape[axis]=len(first)+len(second)+3
                lhs=concatenate_arrays(operands,axis,shape)
                rhs=concatenate_arrays(targets,axis,shape)
                key=f'track={track} rank={rank} axis={axis} other={other} raw={extent},{start},{middle},{stop},{stride}'
                out.append(f'AG_PROFILE {key} counts={len(first)},{len(second)} shape={csv(shape)}')
                for index in coordinates(shape):
                    out.append(f'AG_VALUE {key} index={csv(index)} source={lhs[index]} target={rhs[index]}')
    return out


def pad_lines(track,rank):
    out=[]
    for axis in range(rank):
        for other in (0,1,2):
            for extent in (0,1,3):
                input_shape=[other]*rank;input_shape[axis]=extent
                input_array=materialize(input_shape,lambda i:encode(datum(i),track))
                for width in (0,1,2):
                    for high_side in (False,True):
                        low,high=(0,width) if high_side else (width,0)
                        fill_shape=[other]*rank;fill_shape[axis]=width
                        fill=(fill_shape,materialize(fill_shape,lambda _:encode(71,track)))
                        raw=(input_shape,input_array)
                        shape=[other]*rank;shape[axis]=low+extent+high
                        lhs=concatenate_arrays([raw,fill] if high_side else [fill,raw],axis,shape)
                        # Pad oracle assigns the whole output array first, then copies each input cell.
                        rhs=materialize(shape,lambda _:encode(71,track))
                        for index,value in input_array.items():
                            shifted=list(index);shifted[axis]+=low;rhs[tuple(shifted)]=value
                        key=f'track={track} rank={rank} axis={axis} other={other} extent={extent} low={low} high={high}'
                        out.append(f'PG_PROFILE {key} shape={csv(shape)}')
                        for index in coordinates(shape):
                            out.append(f'PG_VALUE {key} index={csv(index)} source={lhs[index]} target={rhs[index]}')
    return out


def repeat_lines(track,rank):
    out=[]
    for axis in range(rank):
        for other in (0,1,3):
            input_shape=[other]*rank;input_shape[axis]=1
            original=materialize(input_shape,lambda i:encode(datum(i),track))
            dropped=[other]*(rank-1)
            axes=[i for i in range(rank) if i!=axis]
            # Ordinary row-major reshape: retain the input's flat value sequence.
            flattened=[original[index] for index in coordinates(input_shape)]
            reshaped=dict(zip(coordinates(dropped),flattened))
            for copies in (0,1,2,4):
                shape=[other]*rank;shape[axis]=copies
                lhs=concatenate_arrays([(input_shape,original)]*copies,axis,shape)
                rhs=materialize(shape,lambda i:reshaped[tuple(i[a] for a in axes)])
                key=f'track={track} rank={rank} axis={axis} other={other} copies={copies}'
                out.append(f'RG_PROFILE {key} dropped={csv(dropped)} axes={csv(axes)} shape={csv(shape)}')
                for index in coordinates(shape):
                    out.append(f'RG_VALUE {key} index={csv(index)} source={lhs[index]} target={rhs[index]}')
    return out


def expected_lines():
    result=[]
    for rank in (1,2,3):
        for track in ('integer','word8'):result.extend(adjacent_lines(track,rank))
        for track in ('integer','word8'):result.extend(pad_lines(track,rank))
    for rank in (1,2,3):
        for track in ('integer','word8'):result.extend(repeat_lines(track,rank))
    result.extend(f'CG_FLOAT input={bits} repeat={bits} pad={bits}' for bits in BITS)
    return result
