//
//  ViewController.swift
//  TestConversion
//
//  Created by Павел Матюхин on 6/20/20.
//  Copyright © 2020 Павел Матюхин. All rights reserved.
//

import UIKit
import RealityKit
import SceneKit
import ARKit
import VideoToolbox

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    let node1 = SCNNode()
    let node2 = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
            
        print("bug not fixed yet")
        let scnView = SCNView()
        
        scnView.scene = SCNScene()
        
        scnView.allowsCameraControl = true
        scnView.showsStatistics = true
        scnView.backgroundColor = UIColor.darkGray.withAlphaComponent(0.75)
        
        // add camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3Make(0, 0, 2)
        scnView.scene?.rootNode.addChildNode(cameraNode)
        
        
        
        
        let shapeInfo1 = createCustomShape1()
        let shapeInfo2 = createCustomShape2()
        
        node1.geometry = shapeInfo1.0
        node2.geometry = shapeInfo2.0
        
        node1.position.x -= 0.5
        node2.position.x -= 0.5
        
        scnView.scene?.rootNode.addChildNode(node1)
        scnView.scene?.rootNode.addChildNode(node2)
        
        view.addSubview(scnView)
        scnView.frame = CGRect(x: 30, y: 30, width: view.frame.height / 3, height: view.frame.height / 3)
        

        node1.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        node2.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        
        
        
        func doit(){
            
            // NODE 1
            let pixelBuffer = (arView.session.currentFrame?.capturedImage)!
            var cgImage: CGImage?
            VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
            node1.geometry?.firstMaterial?.diffuse.contents = cgImage
            
            // NODE 2
            
            let textures = getCapturedImageTextures(frame: arView.session.currentFrame!)
            
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            
            let descriptor = MTLTextureDescriptor()
            descriptor.pixelFormat = .rgba8Unorm
            descriptor.width = width
            descriptor.height = height
            
            descriptor.usage = [.shaderRead, .shaderWrite]
            
            guard let textureOut = PerformanceShader.shared.device?.makeTexture(descriptor: descriptor) else { return }
            
            PerformanceShader.shared.updateTexture(textureOut, YTexture: textures.YTexture!, CbCrTexture: textures.CbCrTexture!)
            
            node2.geometry?.firstMaterial?.diffuse.contents = textureOut
        }
        
        
        
        
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            doit()
        }
        
    }
    
    
    
    
    
    
}



func createCustomShape1(customCoordinates: [CGPoint]? = nil) -> (SCNGeometry, [SIMD3<Float>], [CGPoint] ) {
    
    let vertex1 = simd_float3(0, 0, 0)
    let vertex2 = simd_float3(1, 0, 0)
    let vertex3 = simd_float3(1, 1, 0)
    
    
    let vertices: [SIMD3<Float>] = [
        vertex1,
        vertex2,
        vertex3,
    ]
    
    let indecies: [Int32] = [
        0,1,2,
    ]
    
    let point1 = CGPoint(x: 0, y: 1)
    let point2 = CGPoint(x: 1, y: 1)
    let point3 = CGPoint(x: 1, y: 0)

    
    let coordinates: [CGPoint] = customCoordinates ?? [
        point1, point2, point3,
    ]
    
    let verticesSource = SCNGeometrySource(vertices: vertices.compactMap{SCNVector3($0)})
    
    let textureCoordinateSource = SCNGeometrySource(textureCoordinates: coordinates)
    
    let element = SCNGeometryElement(indices: indecies, primitiveType: .triangles)
    
    let geometry = SCNGeometry(sources: [verticesSource, textureCoordinateSource], elements: [element])
    
    return (geometry, vertices, coordinates)
}



func createCustomShape2(customCoordinates: [CGPoint]? = nil) -> (SCNGeometry, [SIMD3<Float>], [CGPoint] ) {
    
    let vertex1 = simd_float3(0, 0, 0)
    let vertex3 = simd_float3(1, 1, 0)
    let vertex4 = simd_float3(0, 1, 0)
    
    
    let vertices: [SIMD3<Float>] = [
        vertex1, vertex3, vertex4,
    ]
    
    let indecies: [Int32] = [
        0,1,2,
    ]
    
    let point1 = CGPoint(x: 0, y: 1)
    let point3 = CGPoint(x: 1, y: 0)
    let point4 = CGPoint(x: 0, y: 0)
    
    let coordinates: [CGPoint] = customCoordinates ?? [
        point1, point3, point4,
    ]
    
    let verticesSource = SCNGeometrySource(vertices: vertices.compactMap{SCNVector3($0)})
    
    let textureCoordinateSource = SCNGeometrySource(textureCoordinates: coordinates)
    
    let element = SCNGeometryElement(indices: indecies, primitiveType: .triangles)
    
    let geometry = SCNGeometry(sources: [verticesSource, textureCoordinateSource], elements: [element])
    
    return (geometry, vertices, coordinates)
}





func getCapturedImageTextures(frame: ARFrame) -> (YTexture: MTLTexture?, CbCrTexture: MTLTexture?) {
    // Create two textures (Y and CbCr) from the provided frame's captured image
    let pixelBuffer = frame.capturedImage
    if (CVPixelBufferGetPlaneCount(pixelBuffer) < 2) {
        return (nil, nil)
    }
    
    let capturedImageTextureY = createTexture(fromPixelBuffer: pixelBuffer, pixelFormat:.r8Unorm, planeIndex:0)
    let capturedImageTextureCbCr = createTexture(fromPixelBuffer: pixelBuffer, pixelFormat:.rg8Unorm, planeIndex:1)
    
    return (capturedImageTextureY, capturedImageTextureCbCr)
}


func createTexture(fromPixelBuffer pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat, planeIndex: Int) -> MTLTexture? {
    var mtlTexture: MTLTexture? = nil
    let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
    let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
    

    let device = MTLCreateSystemDefaultDevice()
    
    var capturedImageTextureCache: CVMetalTextureCache!
    
    
    
    guard CVMetalTextureCacheCreate(nil, nil, device!, nil, &capturedImageTextureCache) == kCVReturnSuccess else {
        return nil
    }
    
    
    var texture: CVMetalTexture? = nil
    let status = CVMetalTextureCacheCreateTextureFromImage(nil, capturedImageTextureCache, pixelBuffer, nil, pixelFormat, width, height, planeIndex, &texture)
    if status == kCVReturnSuccess {
        mtlTexture = CVMetalTextureGetTexture(texture!)
    }
    
    return mtlTexture
}
