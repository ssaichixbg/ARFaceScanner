//
//  AR2DFaceManager.swift
//  Alamofire
//
//  Created by Simon on 11/7/17.
//

import UIKit
import ARKit
import Vision

@objc public protocol AR2DFaceManagerDelegate {
    func facesDidUpdate(_ manager: AR2DFaceManager, anchors: [AR2DFaceAnchor])
}

public class AR2DFaceManager: NSObject {
    var faceObservations = [VNFaceObservation]()
    var visionRequests = [VNRequest]()
    var session: ARSession!
    let visionQueue = DispatchQueue(label: "com.yangz.ARFaceScanner.Vision")
    var _faceAnchors = [AR2DFaceAnchor]()
    
    public var faceAnchors: [AR2DFaceAnchor] { return _faceAnchors }
    public var delegate: AR2DFaceManagerDelegate?
    
    public override init() {
        super.init()
        
        setupRequest()
    }
    
    public func start(_ session: ARSession) {
        self.session = session
    }
    
    public func pause() {
        
    }
    
    public func stop() {
        session = nil
        _faceAnchors = []
    }
    
    fileprivate func setupRequest() {
        let faceRequest = VNDetectFaceRectanglesRequest(completionHandler: faceDetectHandler)
        visionRequests = [faceRequest]
    }
    
    fileprivate func updateBinding() {
        guard let frame = session.currentFrame else { return }
        
        _faceAnchors = []
        
        faceObservations.forEach { (obs) in
            let arHitTestResults = frame.hitTest(obs.boundingBox.centerPoint, types: [.featurePoint])
            guard let closestResult = arHitTestResults.first else { return }
            
            let transform : matrix_float4x4 = closestResult.worldTransform
            
            let anchor = AR2DFaceAnchor()
            anchor.ARPosition = vector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            anchor.faceObservation = obs
            
            _faceAnchors.append(anchor)
        }
        
        DispatchQueue.main.async {
            self.delegate?.facesDidUpdate(self, anchors: self._faceAnchors)
        }
        
    }
    
    fileprivate func faceDetectHandler(request: VNRequest, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        guard let observations = request.results else {
            print("No results")
            return
        }
        
        faceObservations = observations.flatMap({ $0 as? VNFaceObservation})
        
        updateBinding()
    }
    
    public func updateDetection() {
        func updateDetection() {
            guard let pixbuff = (session.currentFrame?.capturedImage) else { return }
            //let image = CIImage(cvPixelBuffer: pixbuff).rotate
            //let content =  CIContext()
            //let cgImage = content.createCGImage(image, from: image.extent)
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixbuff, orientation: UIDevice.current.orientation.cameraOrientation, options: [:])
            
            do {
                try imageRequestHandler.perform(visionRequests)
            } catch {
                print(error)
            }
            //            DispatchQueue.main.async {
            //
            //                self.faceHUDView.backgroundImage = cgImage
            //            }
        }
        
        visionQueue.async {
            updateDetection()
        }
    }
}
