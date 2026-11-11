"""Independent integer-stream and materialized tensor oracle for stored-word reinterpretation."""
from itertools import product

WIDTHS=(0,1,3,4,8,16,32)
ORDERS=('lsb','msb')
FLOAT_BITS=(0,0x80000000,0x3f800000,0x7fc01234,0x7f801234,0x7f800000,0xff800000)


def csv(values):return ','.join(map(str,values)) or '-'
def coordinates(shape):return list(product(*(range(n) for n in shape)))
def mask(width):return (1<<width)-1

def reverse_word(value,width):
    return int(f'{value:0{width}b}'[::-1],2) if width else 0


def repack_words(words,width,out_cells,out_width,in_order,out_order):
    assert len(words)*width==out_cells*out_width
    stream=sum((v if in_order=='lsb' else reverse_word(v,width))<<(cell*width)
               for cell,v in enumerate(words))
    chunks=[(stream>>(cell*out_width))&mask(out_width) for cell in range(out_cells)]
    return chunks if out_order=='lsb' else [reverse_word(v,out_width) for v in chunks]


def buffer_lines():
    rows=[]
    for cells,width,out_width in product((0,1,2,3,4),WIDTHS,WIDTHS):
        sizes=(0,2) if out_width==0 else (cells*width//out_width,)
        for out_cells in sizes:
            if cells*width!=out_cells*out_width:continue
            for in_order,out_order,seed in product(ORDERS,ORDERS,(0,1)):
                original=[(305419896+37*cell+113*seed)&mask(width) for cell in range(cells)]
                direct=repack_words(original,width,out_cells,out_width,in_order,out_order)
                bits=repack_words(original,width,cells*width,1,in_order,'msb')
                through=repack_words(bits,1,out_cells,out_width,'msb',out_order)
                back=repack_words(direct,out_width,cells,width,out_order,in_order)
                rows.append(f'BP_BUFFER cells={cells} width={width} out_cells={out_cells} out_width={out_width} '
                            f'in_order={in_order} out_order={out_order} seed={seed} input={csv(original)} '
                            f'direct={csv(direct)} through={csv(through)} back={csv(back)}')
    return rows


def datum(index):return 4660+sum((axis+1)*37*p for axis,p in enumerate(index))


def shape_lines(rank):
    rows=[]
    for other,factor,width,order in product((0,1,2),(0,1,2,4),(1,3,8,16),ORDERS):
        shape=[other]*rank;expanded=shape+[factor]
        source=[datum(index)&mask(factor*width) for index in coordinates(shape)]
        parts=repack_words(source,factor*width,len(coordinates(expanded)),width,order,order)
        back=repack_words(parts,width,len(source),factor*width,order,order)
        arbitrary=[(datum(index)+113)&mask(width) for index in coordinates(expanded)]
        joined=repack_words(arbitrary,width,len(source),factor*width,order,order)
        expanded_back=repack_words(joined,factor*width,len(arbitrary),width,order,order)
        key=f'rank={rank} other={other} factor={factor} width={width} order={order}'
        rows.append(f'BP_SHAPE {key} input_shape={csv(shape)} output_shape={csv(expanded)}')
        for index,value,inverse in zip(coordinates(shape),source,back):
            rows.append(f'BP_ORIGINAL {key} index={csv(index)} source={value} back={inverse}')
        for index,part,value,inverse in zip(coordinates(expanded),parts,arbitrary,expanded_back):
            rows.append(f'BP_PART {key} index={csv(index)} split={part} arbitrary={value} back={inverse}')
    return rows


def physical_coordinates(shape,column):
    axes=list(reversed(range(len(shape)))) if column else list(range(len(shape)))
    result=[]
    for positions in product(*(range(shape[axis]) for axis in axes)):
        index=[0]*len(shape)
        for axis,p in zip(axes,positions):index[axis]=p
        result.append(tuple(index))
    return result


def convert_array(array,in_shape,out_shape,in_col,out_col,width,out_width,in_order,out_order):
    original=[array[index] for index in physical_coordinates(in_shape,in_col)]
    packed=repack_words(original,width,len(coordinates(out_shape)),out_width,in_order,out_order)
    return dict(zip(physical_coordinates(out_shape,out_col),packed))


def boolean(value):return str(value).lower()


def layout_lines():
    rows=[];source_shape=(2,2);middle_shape=(2,2,2);out_shape=(2,4)
    original={index:datum(index)&mask(16) for index in coordinates(source_shape)}
    for in_col,mid_col,out_col in product((False,True),repeat=3):
        for in_order,mid_order,out_order in product(ORDERS,repeat=3):
            middle=convert_array(original,source_shape,middle_shape,in_col,mid_col,16,8,in_order,mid_order)
            through=convert_array(middle,middle_shape,out_shape,mid_col,out_col,8,8,mid_order,out_order)
            direct=convert_array(original,source_shape,out_shape,in_col,out_col,16,8,in_order,out_order)
            key=f'in_col={boolean(in_col)} mid_col={boolean(mid_col)} out_col={boolean(out_col)} '
            key+=f'in_order={in_order} mid_order={mid_order} out_order={out_order}'
            rows.append(f'BP_LAYOUT {key} input_shape=2,2 middle_shape=2,2,2 output_shape=2,4')
            for index in coordinates(out_shape):
                rows.append(f'BP_LAYOUT_VALUE {key} index={csv(index)} direct={direct[index]} through={through[index]}')
        middle_cells=dict(zip(physical_coordinates(source_shape,mid_col),
                              [original[i] for i in physical_coordinates(source_shape,in_col)]))
        mapped={index:value^mask(16) for index,value in middle_cells.items()}
        source=dict(zip(physical_coordinates(source_shape,out_col),
                        [mapped[i] for i in physical_coordinates(source_shape,mid_col)]))
        target=dict(zip(physical_coordinates(source_shape,out_col),
                        [original[i]^mask(16) for i in physical_coordinates(source_shape,in_col)]))
        for index in coordinates(source_shape):
            rows.append(f'BP_CELL in_col={boolean(in_col)} mid_col={boolean(mid_col)} out_col={boolean(out_col)} '
                        f'index={csv(index)} source={source[index]} target={target[index]}')
    return rows


def expected_lines():
    rows=buffer_lines()
    for rank in (0,1,2,3):rows.extend(shape_lines(rank))
    rows.extend(layout_lines())
    for value in FLOAT_BITS:
        chunks=[(value>>(byte*8))&255 for byte in range(4)]
        restored=sum(byte<<(i*8) for i,byte in enumerate(chunks))
        rows.append(f'BP_FLOAT input={value} bytes={csv(chunks)} back={restored}')
    return rows
