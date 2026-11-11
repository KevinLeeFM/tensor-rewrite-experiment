"""Independent dense-array/Boolean oracle for the declared control-value development controls."""
from itertools import product


def expected_lines():
    lines=[]
    for p,x,y in product(range(2),[-17,0,91],[-17,0,91]):
        lines.append(f'CV_SELECT predicate={p} left={x} right={y} value={[y,x][p]}')
    comparisons=dict(lt=lambda a,b:a<b,le=lambda a,b:a<=b,gt=lambda a,b:a>b,
                     ge=lambda a,b:a>=b,eq=lambda a,b:a==b,ne=lambda a,b:a!=b)
    for direction,comparison in comparisons.items():
        for x,y in product(range(2),repeat=2):
            p=int(comparison(x,y));source=[y,x][p]
            target=(min(x,y) if direction in ('lt','le') else max(x,y)
                    if direction in ('gt','ge') else y if direction=='eq' else x)
            assert source==target
            lines.append(f'CV_COMPARE direction={direction} left={x} right={y} predicate={p} source={source} target={target}')
    for axis in range(2):
        values=[int(n%2==0) for n in range([2,3][axis])]
        for row,column in product(range(2),range(3)):
            p=values[[row,column][axis]]
            lines.append(f'CV_BROADCAST axis={axis} row={row} column={column} predicate={p} source={1-p} target={1-p}')
    for p,row,column in product(range(2),range(2),range(3)):
        lines.append(f'CV_SCALAR row={row} column={column} predicate={p} value={p}')
    # Materialize the operand array before selecting argument positions, including duplicates.
    operands=[[(argument+1)*position-3 for position in range(6)] for argument in range(3)]
    for first,second,row,column in product(range(3),range(3),range(2),range(3)):
        index=3*row+column;source=operands[first][index]-2*operands[second][index]
        lines.append(f'CV_MAP first={first} second={second} row={row} column={column} source={source} target={source}')
    for flag,value in product(range(2),[-17,0,91]):
        result=value+[-1,1][flag]
        lines.append(f'CV_HETERO flag={flag} input={value} value={result}')
    for p,state in product(range(2),[0,5]):
        value=[11,13][p]+state
        lines.append(f'CV_CONDITIONAL predicate={p} state={state} source={value} target={value} source_event={p} target_event={p}')
    for p,(x,y) in product(range(2),[(0,0x80000000),(0x7fc01234,0x7f801234),(0x7f800000,0xff800000)]):
        lines.append(f'CV_FLOAT predicate={p} left={x} right={y} bits={[y,x][p]}')
    lines.append('CV_EMPTY coordinates=0')
    return lines
