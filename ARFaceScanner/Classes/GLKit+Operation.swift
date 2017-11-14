//
//  GLKit+Operation.swift
//  ARFaceScanner
//
//  Created by Simon on 11/13/17.
//

import Foundation
import GLKit

infix operator •
infix operator ±

prefix func -(of: GLKVector3) -> GLKVector3 {
    return GLKVector3MultiplyScalar(of, -1)
}

func +(left: GLKVector3, right: GLKVector3) -> GLKVector3 {
    return GLKVector3Add(left, right)
}

func -(left: GLKVector3, right: GLKVector3) -> GLKVector3 {
    return GLKVector3Subtract(left, right)
}
func *(left: GLKVector3, right: GLKVector3) -> GLKVector3 {
    return GLKVector3CrossProduct(left, right)
}
func *(left: GLKVector3, right: GLfloat) -> GLKVector3 {
    return GLKVector3MultiplyScalar(left, right)
}
func *(left: GLfloat, right: GLKVector3) -> GLKVector3 {
    return GLKVector3MultiplyScalar(right, left)
}

func •(left: GLKVector3, right: GLKVector3) -> GLfloat {
    return GLKVector3DotProduct(left, right)
}

func ±(left: GLfloat, right: GLfloat) -> (GLfloat, GLfloat) {
    return (left + right, left - right)
}

func *(left: GLKMatrix4, right: GLKVector3) -> GLKVector3 {
    return GLKMatrix4MultiplyVector3(left, right)
}

func *(left: GLKMatrix4, right: GLKVector4) -> GLKVector4 {
    return GLKMatrix4MultiplyVector4(left, right)
}

func *(left: GLKMatrix4, right: GLKMatrix4) -> GLKMatrix4 {
    return GLKMatrix4Multiply(left, right)
}


extension GLKVector3 {
    var length : GLfloat {
        return GLKVector3Length(self)
    }
    static var eX : GLKVector3 { return GLKVector3Make(1, 0, 0) }
    static var eY : GLKVector3 { return GLKVector3Make(0, 1, 0) }
    static var eZ : GLKVector3 { return GLKVector3Make(0, 0, 1) }
}

extension GLKVector3 : CustomStringConvertible {
    public var description : String {
        return NSStringFromGLKVector3(self)
    }
}

extension GLKVector2 {
    var length : GLfloat {
        return GLKVector2Length(self)
    }
    func normalize() -> GLKVector2 {
        return GLKVector2Normalize(self)
    }
    init(x : Float, y: Float) {
        self = GLKVector2Make(x, y)
    }
}

func +(left: GLKVector2, right: GLKVector2) -> GLKVector2 {
    return GLKVector2Add(left, right)
}
func -(left: GLKVector2, right: GLKVector2) -> GLKVector2 {
    return GLKVector2Subtract(left, right)
}
func *(left: GLKVector2, right: GLfloat) -> GLKVector2 {
    return GLKVector2MultiplyScalar(left, right)
}
func *(left: Float, right: GLKVector2) -> GLKVector2 {
    return GLKVector2MultiplyScalar(right, left)
}
func /(left: GLKVector2, right: GLfloat) -> GLKVector2 {
    return GLKVector2DivideScalar(left, right)
}

extension GLKQuaternion {
    static func lookRotation(forward: GLKVector3, up: GLKVector3) -> GLKQuaternion {
        let vector = GLKVector3Normalize(forward)
        let vector2 = GLKVector3Normalize(up * vector)
        let vector3 = vector * vector2
        
        let m00 = vector2.x
        let m01 = vector2.y
        let m02 = vector2.z
        let m10 = vector3.x
        let m11 = vector3.y
        let m12 = vector3.z
        let m20 = vector.x
        let m21 = vector.y
        let m22 = vector.z
        
        let num8 = (m00 + m11) + m22
        var quaternion = GLKQuaternionMake(0, 0, 0, 0)
        if num8 > 0 {
            var num = sqrt(num8 + 1.0)
            quaternion.w = num * 0.5
            num = 0.5 / num
            quaternion.x = (m12 - m21) * num
            quaternion.y = (m20 - m02) * num
            quaternion.z = (m01 - m10) * num
        }
        else if (m00 >= m11) && (m00 >= m22) {
            let num7 = sqrt(((1.0 + m00) - m11) - m22)
            let num4 = 0.5 / num7
            quaternion.x = 0.5 * num7
            quaternion.y = (m01 + m10) * num4
            quaternion.z = (m02 + m20) * num4
            quaternion.w = (m12 - m21) * num4
        }
        else if m11 > m22 {
            let num6 = sqrt(((1.0 + m11) - m00) - m22)
            let num3 = 0.5 / num6
            quaternion.x = (m10 + m01) * num3
            quaternion.y = 0.5 * num6
            quaternion.z = (m21 + m12) * num3
            quaternion.w = (m20 - m02) * num3
        }
        else {
            let num5 = sqrt(((1.0 + m22) - m00) - m11)
            let num2 = 0.5 / num5
            quaternion.x = (m20 + m02) * num2
            quaternion.y = (m21 + m12) * num2
            quaternion.z = 0.5 * num5
            quaternion.w = (m01 - m10) * num2
        }

        return quaternion;
    }
}
