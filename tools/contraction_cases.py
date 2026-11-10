"""Independent Cartesian-coordinate reference for the bounded Dot pilot."""
import itertools

PROFILES=[
 ('outer00','s32[2]','s32[3]','s32[2,3]','','','','',True,False),
 ('outer01','s32[2]','s8[3]','s32[2,3]','','','','',True,False),
 ('outer10','s8[2]','s32[3]','s32[2,3]','','','','',True,False),
 ('outer11','s8[2]','s8[3]','s32[2,3]','','','','',True,False),
 ('batch_left','s32[3,2]','s32[2,4]','s32[2,3,4]','','','1','0',True,False),
 ('batch_right','s32[2,3]','s32[4,2]','s32[2,3,4]','','','0','1',True,False),
 ('rank4','s32[2,3,2]','s32[2,2]','s32[2,2,3,2]','','','2','1',True,False),
 ('matrix_contract','s32[2,3]','s32[3,4]','s32[2,4]','1','0','','',True,False),
 ('contract_empty','s32[2,0]','s32[0,3]','s32[2,3]','1','0','','',True,False),
 ('lhs_free_empty','s32[0,2]','s32[2,3]','s32[0,3]','1','0','','',True,False),
 ('rhs_free_empty','s32[2,3]','s32[3,0]','s32[2,0]','1','0','','',True,False),
 ('scalar_outer','s32[]','s32[2]','s32[2]','','','','',True,False),
 ('outer_free_empty','s32[0]','s32[3]','s32[0,3]','','','','',True,False),
 ('option_off','s32[2]','s32[3]','s32[2,3]','','','','',False,False),
 ('layout_on','s32[2]','s32[3]','s32[2,3]','','','','',True,True),
 ('f32_negative_zero','f32[2]','f32[3]','f32[2,3]','','','','',True,False),
 ('f32_positive_zero','f32[2]','f32[3]','f32[2,3]','','','','',True,False),
 ('f32_negative_result','f32[2]','f32[3]','f32[2,3]','','','','',True,False),
 ('f32_zero_option_off','f32[2]','f32[3]','f32[2,3]','','','','',False,False),
]


def shape(text):
    inner=text.split('[')[1].split(']')[0]
    return [] if not inner else list(map(int,inner.split(',')))


def coordinates(extents):
    return itertools.product(*(range(n) for n in extents))


def label(extents,index):
    position=0
    for n,i in zip(extents,index):position=position*n+i
    return position+1


def word_values(profile):
    name,ls,rs,out,*_=profile
    result=[]
    for index in coordinates(shape(out)):
        if name=='matrix_contract':value=sum(label(shape(ls),(index[0],k))*label(shape(rs),(k,index[1])) for k in range(3))
        elif name=='contract_empty':value=0
        elif name=='batch_left':value=label(shape(ls),(index[1],index[0]))*label(shape(rs),(index[0],index[2]))
        elif name=='batch_right':value=label(shape(ls),(index[0],index[1]))*label(shape(rs),(index[2],index[0]))
        elif name=='rank4':value=label(shape(ls),(index[1],index[2],index[0]))*label(shape(rs),(index[3],index[0]))
        elif name=='scalar_outer':value=2*[5,-3][index[0]]
        else:value=[2,-3][index[0]]*[5,7,-2][index[1]]
        result.append(value)
    return result


def changed(profile,mode):
    return mode!='control' and profile[8] and not profile[9] and profile[0]!='matrix_contract'


def expected_word_rows():
    return [(p[0],m,str(int(changed(p,m))),str(len(word_values(p))),','.join(map(str,word_values(p))) or 'empty')
            for p in PROFILES if not p[0].startswith('f32_') for m in ('control','handler','pass')]


def fp_bits(name,active):
    if name=='f32_negative_result':return [0xc0000000,0xc0800000,0xc0c00000,0x40400000,0x40c00000,0x41100000]
    return [0x80000000]*3+[0]*3 if name=='f32_negative_zero' and active else [0]*6


def expected_fp_rows():
    return [(p[0],m,str(int(changed(p,m))),','.join(map(str,fp_bits(p[0],False))),
             ','.join(map(str,fp_bits(p[0],changed(p,m)))),
             str(int(fp_bits(p[0],False)==fp_bits(p[0],changed(p,m)))))
            for p in PROFILES if p[0].startswith('f32_') for m in ('control','handler','pass')]
