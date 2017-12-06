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
    
    var mid: vector_float3 {
        let sortedArr = sorted(by: { $0.x + $0.y >= $1.x + $1.y })
        return sortedArr[count / 2]
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

public class ARFSFaceLandmarks: NSObject {
    enum Keys: String {
        case leftEye
        case rightEye
        case medianLine
        case outerLips
        case innerLips
        
        static var All: [Keys] = [.leftEye, .rightEye, medianLine, .outerLips, .innerLips]
        var visionLandmarkKey: String {
            return rawValue
        }
    }
    
    var sampleValues = [
        Keys.leftEye: [float3](),
        Keys.rightEye: [float3](),
        Keys.medianLine: [float3](),
        Keys.outerLips: [float3](),
        Keys.innerLips: [float3](),
    ]
    
    public var leftEye: [float3] { return sampleValues[.leftEye]! }
    public var rightEye: [float3] { return sampleValues[.rightEye]! }
    public var medianLine: [float3] { return sampleValues[.medianLine]! }
    public var outerLips: [float3] { return sampleValues[.outerLips]! }
    public var innerLips: [float3] { return sampleValues[.innerLips]! }
}

extension Array where Element == ARFSFaceLandmarks {
    var mean: ARFSFaceLandmarks {
        let landmark = ARFSFaceLandmarks()
        ARFSFaceLandmarks.Keys.All.forEach({ key in
            let samples = [self.map({ $0.sampleValues[key]!.mean }).mean]
            landmark.sampleValues[key] = samples
        })
        return landmark
    }
}

public class ARFSFaceAnchor: NSObject {
    var faceImage: UIImage?
    public var faceID: Int = 0
    // 3D
    public var facePosition: float3 = vector3(0, 0, 0)
    public var faceLookAt: float3 = vector3(0, 0, 0)
    public var faceLookUp: float3 = vector3(0, 0, 0)
    public var faceRotation: float4 = vector4(0, 0, 0, 0)
    public var faceScale: float3 = vector3(0, 0, 0)
    //public var faceTransform: GLKMatrix4 = GLKMatrix4()
    public var landmarks: ARFSFaceLandmarks?
    public var pointClouds = [float3]()
    
    // 2D
    public var face2DBoundingBox: CGRect = CGRect.zero
    public var point2DClouds = [CGPoint]()
    
    // Raw data
    public var faceObservation: VNFaceObservation?
    
    public var sampleCount: Int { return samples.count }
    
    var samples = [(pos: float3, lookat: float3, landmark: ARFSFaceLandmarks)]()
    var scaleSamples = [float3]()
    var lastUpdate: TimeInterval = 0.0 {
        didSet {
            _update()
        }
    }
    
    private static var sharedFaceCounter: Int = 0
    
    public override init() {
        super.init()
        
        DispatchQueue.main.sync {
            ARFSFaceAnchor.sharedFaceCounter += 1
             self.faceID = ARFSFaceAnchor.sharedFaceCounter
        }
       
    }
    
    func _update() {
        facePosition = samples.map({ $0.pos }).mean
        landmarks = samples.map({ $0.landmark }).mean
        
        if faceScale.x == 0 && scaleSamples.count > 10{
            faceScale = scaleSamples.mid
        }
        
        faceLookAt =  samples.map({ $0.lookat }).mean
    }
}

