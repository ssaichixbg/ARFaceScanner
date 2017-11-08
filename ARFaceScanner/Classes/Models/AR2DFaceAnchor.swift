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

public class AR2DFaceAnchor: NSObject {
    var faceImage: UIImage?
    public var ARPosition: vector_float3 = vector3(0, 0, 0);
    public var faceObservation: VNFaceObservation?
}

