//
//  Utilities.swift
//  ARFace
//
//  Created by Simon on 10/9/17.
//  Copyright © 2017 zhangy405. All rights reserved.
//

import Foundation
import UIKit
import ARKit

public extension CGRect {
    var centerPoint: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
    var topLeft: CGPoint {
        return CGPoint(x: minX, y: minY)
    }
    var bottomRight: CGPoint {
        return CGPoint(x: maxX, y: maxY)
    }
    var topRight: CGPoint {
        return CGPoint(x: maxX, y: minY)
    }
}

extension CGPoint {
    var sim_vector: vector_float2 {
        return vector2(Float(x), Float(x))
    }
    var glVector: GLKVector2 {
        return GLKVector2Make(Float(x), Float(y))
    }
}

public extension UIFont {
    // Based on: https://stackoverflow.com/questions/4713236/how-do-i-set-bold-and-italic-on-uilabel-of-iphone-ipad
    func withTraits(traits:UIFontDescriptorSymbolicTraits...) -> UIFont {
        let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptorSymbolicTraits(traits))
        return UIFont(descriptor: descriptor!, size: 0)
    }
}


extension UIImage {
    public convenience init(view: UIView, in rect: CGRect) {
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let cgImage = image?.cgImage?.cropping(to: rect)
        self.init(cgImage: cgImage!)
    }
}


public extension UIDeviceOrientation {
    var cameraOrientation: CGImagePropertyOrientation {
        switch self {
        case .landscapeLeft: return .upMirrored
        case .landscapeRight: return .downMirrored
        case .portraitUpsideDown: return .rightMirrored
        default: return .leftMirrored
        }
    }
}

extension GLKVector3 {
    var sim_vector: vector_float3 {
        return vector3(x, y, z)
    }
}

extension GLKQuaternion {
    var sim_quaternion: simd_quatf {
        return simd_quaternion(vector4(x, y, z, w))
    }
}

extension ARFrame {
    func viewTransform(for orientation: UIInterfaceOrientation, viewportSize: CGSize) -> CGAffineTransform {
        return CGAffineTransform(scaleX: viewportSize.width, y: viewportSize.height).concatenating(CGAffineTransform(scaleX: -1.0, y: -1.0).concatenating(CGAffineTransform(translationX: viewportSize.width, y: viewportSize.height)))
    }
    
    func rawFeaturPoints(in rect: CGRect, orientation: UIInterfaceOrientation, viewportSize: CGSize) ->
        [(projection: CGPoint, worldPosition: GLKVector3)]{
        guard let points = rawFeaturePoints else { return []}
        
        var rangedPoints = [(projection: CGPoint, worldPosition: GLKVector3)]()
        let displayRect = rect.applying(
                viewTransform(for: orientation, viewportSize: viewportSize)
            )
        points.points.forEach { (p) in
            let projection = camera.projectPoint(
                p, orientation: orientation,
                viewportSize: viewportSize
            )
            if displayRect.contains(projection) {
                rangedPoints.append((projection: projection, worldPosition: GLKVector3Make(p.x, p.y, p.z)))
            }
        }
        
        return rangedPoints.sorted(by:
            { $0.projection.x + $0.projection.y > $1.projection.x + $1.projection.y
                
        })
    }
}

func VectorConverter(
    point1: (projection: CGPoint, worldPosition: GLKVector3),
    point2: (projection: CGPoint, worldPosition: GLKVector3),
    point3: (projection: CGPoint, worldPosition: GLKVector3)
    ) -> ((GLKVector2) -> GLKVector3) {
    let worldBase1 = (point2.worldPosition - point1.worldPosition)
    let worldBase2 = (point3.worldPosition - point1.worldPosition)
    let viewBase1 = point2.projection.glVector - point1.projection.glVector
    let viewBase2 = point3.projection.glVector - point1.projection.glVector
    
    return { (point) in
        let vector = point - point1.projection.glVector
        let a = (viewBase2.y * vector.x - viewBase2.x * vector.y) / (viewBase2.y * viewBase1.x - viewBase2.x * viewBase1.y)
        let b = (viewBase1.y * vector.x - viewBase1.x * vector.y) / (viewBase1.y * viewBase2.x - viewBase1.x * viewBase2.y)
        
        return a * worldBase1 + b * worldBase2 + point1.worldPosition
    }
}
