//
//  Face.swift
//  ARFace
//
//  Created by Simon on 10/18/17.
//  Copyright © 2017 zhangy405. All rights reserved.
//

import UIKit
import ARKit
import Vision

extension Array where Element == vector_float3 {
    var mean: vector_float3 {
        let count = Float(self.count)
        let sum = reduce(vector3(0, 0, 0), {
            vector3($0.x + $1.x, $0.y + $1.y, $0.z + $1.z)
        })
        return vector3(sum.x / count, sum.y / count, sum.z / count)
    }
}

extension Array where Element == simd_quatf {
    var mean: simd_quatf {
        let count = Float(self.count)
        return reduce(simd_quatf(), {
            $0 + $1 / count
        })
    }
}

public class AR2DFaceAnchor: NSObject {
    var faceImage: UIImage?
    public var faceID: Int = 0
    public var facePosition: vector_float3 = vector3(0, 0, 0)
    public var faceRotation: simd_quatf = simd_quaternion(vector4(0, 0, 0, 0))
    public var faceScale: vector_float3 = vector3(0, 0, 0)
    public var faceTransform: matrix_float4x4 =
        matrix_from_rows(vector4(0, 0, 0, 0), vector4(0, 0, 0, 0), vector4(0, 0, 0, 0), vector4(0, 0, 0, 0))
    public var face2DBoundingBox: CGRect = CGRect.zero
    
    public var pointClouds = [vector_float3]()
    public var point2DClouds = [CGPoint]()
    public var faceObservation: VNFaceObservation?
    
    public var sampleCount: Int { return samples.count }
    
    var samples = [(pos: vector_float3, rot: simd_quatf, sca:vector_float3)]()
    var lastUpdate: TimeInterval = 0.0 {
        didSet {
            _update()
        }
    }
    
    private static var sharedFaceCounter: Int = 0
    
    public override init() {
        super.init()
        
        DispatchQueue.main.sync {
            AR2DFaceAnchor.sharedFaceCounter += 1
             self.faceID = AR2DFaceAnchor.sharedFaceCounter
        }
       
    }
    
    func _update() {
        facePosition = samples.map({ $0.pos }).mean
        faceScale = samples.map({ $0.sca }).mean
        faceRotation = samples.map({ $0.rot }).mean
    }
}

