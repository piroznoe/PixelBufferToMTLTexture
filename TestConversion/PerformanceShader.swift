//
//  PerformanceShader.swift
//  GPUCalculations
//
//  Created by Павел Матюхин on 6/16/20.
//  Copyright © 2020 Павел Матюхин. All rights reserved.
//


import Foundation
import simd
import MetalKit
import ReplayKit
import ARKit
import MetalPerformanceShaders


class PerformanceShader {
    
    // MARK: - Properties
    
    static let shared: PerformanceShader = PerformanceShader()
    
    let device: MTLDevice?
    
    let commandQueue: MTLCommandQueue?
    
    let library: MTLLibrary?
    
    
    
    let renderTextureFunc: MTLFunction?
    
    let renderTexturePiplineState: MTLComputePipelineState?
    
    
    // MARK: - Init
    
    fileprivate init(){
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device?.makeCommandQueue()
        library = device?.makeDefaultLibrary()
        
        
        
        renderTextureFunc = (library?.makeFunction(name: "renderTexture"))!
        
        renderTexturePiplineState = try! device?.makeComputePipelineState(function: renderTextureFunc!)
    }
    
    
    
    
    // MARK: - Handlers
    
    
    //    MARK: - Vertices
    
    
    
    //    MARK: - Texture
    
    
    
        
        @discardableResult
        func updateTexture(_ texture: MTLTexture,
                           YTexture: MTLTexture,
                           CbCrTexture: MTLTexture) -> MTLTexture? {
            
            guard
                let commandQueue = commandQueue,
                let renderTexturePiplineState = renderTexturePiplineState
                
                else {
                    assertionFailure()
                    return nil
            }
            
            let textureCommandBuffer = commandQueue.makeCommandBuffer()
            let textureComputeEncoder = textureCommandBuffer?.makeComputeCommandEncoder()
            
            textureComputeEncoder?.setComputePipelineState(renderTexturePiplineState)
            
            
            
            
            let textureOut = texture
            
            

            
            textureComputeEncoder?.setTexture(YTexture,    index: 0)
            textureComputeEncoder?.setTexture(CbCrTexture, index: 1)
            textureComputeEncoder?.setTexture(textureOut,  index: 2)
            
           
            
            
            let w = renderTexturePiplineState.threadExecutionWidth
            let h = renderTexturePiplineState.maxTotalThreadsPerThreadgroup / w
            let threadsPerThreadgroup = MTLSizeMake(w, h, 1)
            
            textureComputeEncoder?.dispatchThreads(MTLSize(width: YTexture.width, height: YTexture.height, depth: 1), threadsPerThreadgroup: threadsPerThreadgroup)
            
            
            textureComputeEncoder?.endEncoding()
            
            
            textureCommandBuffer?.commit()
            textureCommandBuffer?.waitUntilCompleted()
            
          
            
            
            return textureOut
        }
        
        
        
    }
