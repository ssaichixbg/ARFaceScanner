//
//  Utilities.swift
//  ARFace
//
//  Created by Simon on 10/9/17.
//  Copyright © 2017 zhangy405. All rights reserved.
//

import Foundation
import UIKit

public extension CGRect {
    func denomalize(to rect: CGRect) -> CGRect {
        let transform = CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -rect.width, y: -rect.height)
        let translate = CGAffineTransform.identity.scaledBy(x: rect.width, y: rect.height)
        return applying(translate).applying(transform)
    }
    
    var centerPoint: CGPoint {
        return CGPoint(x: midX, y: midY)
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
