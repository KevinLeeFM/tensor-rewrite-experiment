"""Independent finite integer sums for declared convolution-model examples, not code correspondence."""
from itertools import product


def evaluate(*, inputs=(5,), kernels=(2,), strides=None, bases=None, dilations=None,
             low=None, high=None, reverse=False, batch_group=0, feature_group=0,
             channels=1, output=None, scale=1, bias=0, output_scale=1, pre_bias=0, channel_stride=10, channel_weight_base=None, output_feature_factor=1):
    rank=len(inputs)
    strides=strides or (1,)*rank; bases=bases or (1,)*rank
    dilations=dilations or (1,)*rank; low=low or (0,)*rank; high=high or (0,)*rank
    output=output or (0,)*rank
    def dilated(size,dilation):return 0 if size==0 else (size-1)*dilation+1
    extents=[max(0,(l+dilated(n,b)+h-dilated(k,d))//s+1)
             for n,k,s,b,d,l,h in zip(inputs,kernels,strides,bases,dilations,low,high)]
    if any(not 0<=o<n for o,n in zip(output,extents)):return None
    total=0
    for channel in range(channels):
        for kernel in product(*(range(n) for n in kernels)):
            dilated_coords=[o*s+(kmax-1-k if reverse else k)*d-l
                            for o,s,k,kmax,d,l in zip(output,strides,kernel,kernels,dilations,low)]
            if any(q<0 or q%b or q//b>=n for q,b,n in zip(dilated_coords,bases,inputs)):continue
            coords=[q//b for q,b in zip(dilated_coords,bases)]
            value=batch_group*100+(feature_group*channels+channel)*channel_stride+1
            value+=sum(c*10**(rank-1-i) for i,c in enumerate(coords))
            weight=((channel+channel_weight_base) if channel_weight_base is not None else
                    (kernel[0]+1 if rank==1 else 1))*scale*output_feature_factor
            total+=value*weight
    return (total+bias+pre_bias)*output_scale


def expected_rows():
    profiles=[('plain',{}),('grouped',dict(batch_group=1,feature_group=1,output=(1,))),
      ('reversed',dict(batch_group=1,feature_group=1,output=(1,),reverse=True)),
      ('padded',dict(low=(1,),high=(1,))),('cropped',dict(low=(-1,))),
      ('base_dilation_even',dict(inputs=(3,),bases=(2,))),
      ('base_dilation_hole',dict(inputs=(3,),bases=(2,),output=(1,))),
      ('kernel_dilation',dict(dilations=(2,))),('stride',dict(strides=(2,),output=(1,))),
      ('empty_input_padded',dict(inputs=(0,),low=(2,),high=(2,))),
      ('empty_kernel',dict(kernels=(0,))),('no_channels',dict(channels=0)),
      ('two_channels',dict(channels=2)),('out_of_output_bounds',dict(output=(4,))),
      ('two_dimensional_low',dict(inputs=(3,3),kernels=(2,2))),
      ('two_dimensional_high',dict(inputs=(3,3),kernels=(2,2),output=(1,1))),
      ('bias_scale_output',dict(batch_group=1,feature_group=1,output=(1,),pre_bias=5,output_scale=3)),
      ('bias_scale_kernel',dict(batch_group=1,feature_group=1,output=(1,),scale=3,bias=15)),
      ('output_feature_zero',dict(inputs=(3,),kernels=(1,))),
      ('output_feature_one',dict(inputs=(3,),kernels=(1,),output_feature_factor=2)),
      ('output_feature_scaled',dict(inputs=(3,),kernels=(1,),output_feature_factor=2,scale=3)),
      ('no_spatial_axes',dict(inputs=(),kernels=(),channels=2,channel_stride=1,channel_weight_base=3))]
    return [(name,'none' if (value:=evaluate(**args)) is None else str(value)) for name,args in profiles]
