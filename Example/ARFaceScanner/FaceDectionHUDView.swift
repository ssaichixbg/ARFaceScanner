//
//  FaceDectionHUDView.swift
//  ARFace
//
//  Created by Simon on 10/8/17.
//  Copyright © 2017 zhangy405. All rights reserved.
//

import UIKit

class FaceDectionHUDView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        backgroundColor = UIColor.clear
    }
    
    var faceBoxes: [CGRect] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var debugPoints: [CGPoint] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var backgroundImage: CGImage? {
        didSet { setNeedsDisplay() }
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Drawing code
        faceBoxes.forEach { (box) in
            context.setStrokeColor(UIColor.yellow.cgColor)
            context.stroke(box)
        }
        debugPoints.forEach { (point) in
            let box = CGRect(origin: point, size: CGSize.zero).insetBy(dx: -4, dy: -4)
            context.setStrokeColor(UIColor.blue.cgColor)
            context.strokeEllipse(in: box)
        }
        //        if let backgroundImage = backgroundImage {
        //            UIGraphicsGetCurrentContext()?.draw(backgroundImage, in: rect)
        //        }
    }
    
    
}

