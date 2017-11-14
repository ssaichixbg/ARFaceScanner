//
//  AR2DFaceManager.swift
//  Alamofire
//
//  Created by Simon on 11/7/17.
//

import UIKit
import ARKit
import GLKit
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
    public var started: Bool { return session != nil }
    public var orientation: UIInterfaceOrientation = .portrait
    public var viewportSize: CGSize = CGSize.zero
    
    public override init() {
        super.init()
        
        setupRequest()
    }
    
    public func start(_ session: ARSession, viewportSize: CGSize) {
        self.session = session
        self.viewportSize = viewportSize
    }
    
    public func pause() {
        
    }
    
    public func stop() {
        session = nil
        _faceAnchors = []
    }
    
    fileprivate func setupRequest() {
        let faceRequest = VNDetectFaceLandmarksRequest(completionHandler: faceDetectHandler)
        visionRequests = [faceRequest]
    }
    
    fileprivate func updateBinding() {
        
        guard let frame = session.currentFrame else { return }
        
        faceObservations.forEach { (obs) in
            var arHitTestResults = frame.rawFeaturPoints(in: obs.boundingBox, orientation: orientation, viewportSize: viewportSize)
            guard arHitTestResults.count >= 3 else { return }
            let point1 = arHitTestResults.first!
            let point2 = arHitTestResults.last!
            let point3 = arHitTestResults[arHitTestResults.count / 2]
            let viewTransform = frame.viewTransform(for: orientation, viewportSize: viewportSize)
            let boxCenter2DPoint = obs.boundingBox.centerPoint.applying(viewTransform)
            let convert = VectorConverter(point1: point1, point2: point2, point3: point3)
            
            let faceCenter = convert(boxCenter2DPoint.glVector)
            let vertex = [obs.boundingBox.topLeft, obs.boundingBox.topRight, obs.boundingBox.bottomRight].map({
                return convert($0.applying(viewTransform).glVector)
            })
            
            // find anchor
            let existingAnchor: AR2DFaceAnchor? = _faceAnchors.filter({ (anchor) in
                let position = anchor.facePosition
                let positionVector = GLKVector3Make( position.x, position.y, position.z)
                return (positionVector - faceCenter).length < 0.1
            }).first
            var anchor: AR2DFaceAnchor
            if let existingAnchor = existingAnchor {
                anchor = existingAnchor
            }
            else {
                // create a face anchor
                anchor = AR2DFaceAnchor()
                _faceAnchors.append(anchor)
            }
            
            anchor.samples.append((
                pos: faceCenter.sim_vector,
                rot: GLKQuaternion.lookRotation(forward: (vertex[0] - vertex[1]) * (vertex[1] - vertex[2]), up: (vertex[1] - vertex[2])).sim_quaternion,
                sca: GLKVector3Make((vertex[0] - vertex[1]).length, (vertex[1] - vertex[2]).length, 0.2).sim_vector
            ))

            anchor.face2DBoundingBox = obs.boundingBox.applying(viewTransform)
            anchor.faceObservation = obs
            anchor.pointClouds = arHitTestResults.map({ $0.worldPosition.sim_vector })
            anchor.point2DClouds = arHitTestResults.map({ $0.projection })
            if anchor.samples.count >= 20 {
                anchor.samples.removeFirst()
            }
            anchor.lastUpdate = frame.timestamp
            
            _faceAnchors = _faceAnchors.filter({ frame.timestamp - $0.lastUpdate < 0.3 })
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
        }
        
        visionQueue.async {
            updateDetection()
        }
    }
}
