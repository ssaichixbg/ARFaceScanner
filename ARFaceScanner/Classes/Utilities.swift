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
    func denomalize(to rect: CGRect) -> CGRect {
        let transform = CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -rect.width, y: -rect.height)
        let translate = CGAffineTransform.identity.scaledBy(x: rect.width, y: rect.height)
        return applying(translate).applying(transform)
    }
    
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
    
    var uiOrientation: UIInterfaceOrientation {
        switch self {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        default:
            return .portrait
        }
    }
}

extension GLKVector3 {
    public var sim_vector: vector_float3 {
        return vector3(x, y, z)
    }
}

extension GLKQuaternion {
    public var sim_quaternion: simd_quatf {
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

extension ARCamera {
    var ray: GLKVector4 {
        return transform.glk_matrix * GLKVector3.forward.pointVector4
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

extension Array where Element == float3 {
    var fittedLine: GLKVector3? {
        guard let first = first, let last = last, first != last else { return nil }
        
        return (first.glk_vector - last.glk_vector).normal
    }
}

public func CreateMatchingBackingDataWithImage(imageRef: CGImage?, orienation: UIImageOrientation) -> CGImage? {
    var orientedImage: CGImage?
    
    if let imageRef = imageRef {
        let originalWidth = imageRef.width
        let originalHeight = imageRef.height
        let bitsPerComponent = imageRef.bitsPerComponent
        let bytesPerRow = imageRef.bytesPerRow
        
        let colorSpace = imageRef.colorSpace
        let bitmapInfo = imageRef.bitmapInfo
        
        var degreesToRotate: Double
        var swapWidthHeight: Bool
        var mirrored: Bool
        switch orienation {
        case .up:
            degreesToRotate = 0.0
            swapWidthHeight = false
            mirrored = false
            break
        case .upMirrored:
            degreesToRotate = 0.0
            swapWidthHeight = false
            mirrored = true
            break
        case .right:
            degreesToRotate = 90.0
            swapWidthHeight = true
            mirrored = false
            break
        case .rightMirrored:
            degreesToRotate = 90.0
            swapWidthHeight = true
            mirrored = true
            break
        case .down:
            degreesToRotate = 180.0
            swapWidthHeight = false
            mirrored = false
            break
        case .downMirrored:
            degreesToRotate = 180.0
            swapWidthHeight = false
            mirrored = true
            break
        case .left:
            degreesToRotate = -90.0
            swapWidthHeight = true
            mirrored = false
            break
        case .leftMirrored:
            degreesToRotate = -90.0
            swapWidthHeight = true
            mirrored = true
            break
        }
        let radians = degreesToRotate * Double.pi / 180
        
        var width: Int
        var height: Int
        if swapWidthHeight {
            width = originalHeight
            height = originalWidth
        } else {
            width = originalWidth
            height = originalHeight
        }
        
        if let contextRef = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace!, bitmapInfo: bitmapInfo.rawValue) {
            
            contextRef.translateBy(x: CGFloat(width) / 2.0, y: CGFloat(height) / 2.0)
            if mirrored {
                contextRef.scaleBy(x: -1.0, y: 1.0)
            }
            contextRef.rotate(by: CGFloat(radians))
            if swapWidthHeight {
                contextRef.translateBy(x: -CGFloat(height) / 2.0, y: -CGFloat(width) / 2.0)
            } else {
                contextRef.translateBy(x: -CGFloat(width) / 2.0, y: -CGFloat(height) / 2.0)
            }
            contextRef.draw(imageRef, in: CGRect(x: 0, y: 0, width: originalWidth, height: originalHeight))
            
            orientedImage = contextRef.makeImage()
        }
    }
    
    return orientedImage
}
