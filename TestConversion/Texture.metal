//
//  Texture.metal
//  ARTEST
//
//  Created by Павел Матюхин on 6/15/20.
//  Copyright © 2020 Павел Матюхин. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;





kernel void renderTexture(texture2d<float, access::sample> capturedImageTextureY [[ texture(0) ]],
                          texture2d<float, access::sample> capturedImageTextureCbCr [[ texture(1) ]],
                          
                          texture2d<float, access::read_write> outTextue [[texture(2)]],
                          
                          
                          uint2 size [[threads_per_grid]],
                          uint2 pid [[thread_position_in_grid]]){
    
    
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);
    
    
    const float4x4 ycbcrToRGBTransform = float4x4(
        float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
        float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
        float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
        float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
    );
    
    float2 texCoord;
    texCoord.x = float(pid.x) / size.x;
    texCoord.y = float(pid.y) / size.y;
    
    // Sample Y and CbCr textures to get the YCbCr color at the given texture coordinate
    float4 ycbcr = float4(capturedImageTextureY.sample(colorSampler,    texCoord).r,
                          capturedImageTextureCbCr.sample(colorSampler, texCoord).rg, 1.0);

    float4 color = ycbcrToRGBTransform * ycbcr;
    
    
    outTextue.write(color, pid);
}





