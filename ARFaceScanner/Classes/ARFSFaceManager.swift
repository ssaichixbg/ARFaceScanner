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

extension Array where Element == CGPoint {
    var mean: CGPoint {
        let count = CGFloat(self.count)
        let sum = reduce(CGPoint.zero, {
            CGPoint(x: $0.x + $1.x, y: $0.y + $1.y)
        })
        return CGPoint(x: sum.x / count,y: sum.y / count)
    }
}

extension CGPoint {
    func distance(p2: CGPoint) -> Float {
        return Float(sqrt(pow(x - p2.x, 2) + pow(y - p2.y, 2)))
    }
}

extension VNFaceLandmarkRegion2D {
    func pointsInImageUpsideDown(imageSize: CGSize) -> [CGPoint] {
        let updownTransform = CGAffineTransform(scaleX: -1, y: -1).concatenating(CGAffineTransform(translationX: imageSize.width, y: imageSize.height))
        return pointsInImage(imageSize:imageSize).map({ $0.applying(updownTransform)})
    }
}

@objc public protocol ARFSFaceManagerDelegate {
    @objc optional func facesDidUpdate(_ manager: ARFSFaceManager, anchors: [ARFSFaceAnchor])
    @objc optional func newFaceDidAdd(_ manager: ARFSFaceManager, anchor: ARFSFaceAnchor)
}

public class ARFSFaceManager: NSObject {
    var faceObservations = [VNFaceObservation]()
    var trackingObservations = [VNDetectedObjectObservation]()
    var visionRequests = [VNRequest]()
    var session: ARSession!
    let visionQueue = DispatchQueue(label: "com.yangz.ARFaceScanner.Vision")
    var _faceAnchors = [UUID: ARFSFaceAnchor]()
    var _faceRequests = [UUID: VNTrackObjectRequest]()
    var _trackingLastUpdate = [UUID: TimeInterval]()
    
    public var faceAnchors: [ARFSFaceAnchor] { return Array(_faceAnchors.values) }
    public var delegate: ARFSFaceManagerDelegate?
    public var started: Bool { return session != nil }
   // public var orientation: UIInterfaceOrientation = .portrait
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
        _faceAnchors.removeAll()
    }
    
    fileprivate func setupRequest() {
        let faceRequest = VNDetectFaceLandmarksRequest(completionHandler: faceDetectHandler)
        visionRequests = [faceRequest]
    }
    
    fileprivate func addTrackingRequest(faceObj: VNFaceObservation) {
        let trackingRequest = VNTrackObjectRequest(detectedObjectObservation: faceObj, completionHandler: trackingHandler)
        visionRequests.append(trackingRequest)
        _faceRequests[faceObj.uuid] = trackingRequest
        _trackingLastUpdate[faceObj.uuid] = Date().timeIntervalSince1970
        NSLog("add face \(faceObj.uuid)")
    }
    
    fileprivate func getFaceObservation(frame: CGRect) -> VNFaceObservation? {
        return faceObservations.filter({
             $0.boundingBox.intersects(frame)
        }).first
    }
    
    fileprivate func getPlaneFeaturePoints(points: [(projection: CGPoint, worldPosition: GLKVector3)], landmark: VNFaceLandmarks2D, viewportSize: CGSize) -> [(projection: CGPoint, worldPosition: GLKVector3)] {

        let leftEye = landmark.leftEye!.pointsInImageUpsideDown(imageSize: viewportSize).mean
        let rightEye = landmark.rightEye!.pointsInImageUpsideDown(imageSize: viewportSize).mean
        let lip = landmark.outerLips!.pointsInImageUpsideDown(imageSize: viewportSize).mean
        //var selectedPoints = [(projection: CGPoint, worldPosition: GLKVector3)]()
        var oriPoints = Array(points)
        let point1 = oriPoints.enumerated().map({ (i: $0, point: $1, distance: $1.projection.distance(p2: leftEye)) }).min(by: { $0.distance < $1.distance })!
        oriPoints.remove(at: point1.i)
        let point2 = oriPoints.enumerated().map({ (i: $0, point: $1, distance: $1.projection.distance(p2: rightEye)) }).min(by: { $0.distance
            < $1.distance })!
        oriPoints.remove(at: point2.i)
        let point3 = oriPoints.enumerated().map({ (i: $0, point: $1, distance: $1.projection.distance(p2: lip)) }).min(by: { $0.distance < $1.distance })!
        return [point1, point2, point3].map({ $0.point })
    }
    
    fileprivate func updateBinding() {
        
        guard let frame = session.currentFrame else { return }
        let orientation: UIInterfaceOrientation = UIDevice.current.orientation.uiOrientation
        var newAnchors = [ARFSFaceAnchor]()
        
        trackingObservations.forEach { (obs) in
            guard let faceObs = getFaceObservation(frame: obs.boundingBox) else { return }
            
            var arHitTestResults = frame.rawFeaturPoints(in: faceObs.boundingBox, orientation: orientation, viewportSize: viewportSize)
            guard arHitTestResults.count >= 3 else { return }
            
            let viewTransform = frame.viewTransform(for: orientation, viewportSize: viewportSize)
            var planeFeaturePoints = getPlaneFeaturePoints(points: arHitTestResults, landmark: faceObs.landmarks!, viewportSize: viewportSize)
            let point1 = planeFeaturePoints[0]//arHitTestResults.first!
            let point2 = planeFeaturePoints[1]//arHitTestResults.last!
            let point3 = planeFeaturePoints[2]//arHitTestResults[arHitTestResults.count / 2]

            let boxCenter2DPoint = faceObs.boundingBox.centerPoint.applying(viewTransform)
            let convert = VectorConverter(point1: point1, point2: point2, point3: point3)
            
            let faceCenter = convert(boxCenter2DPoint.glVector)
            let vertex = [faceObs.boundingBox.topLeft, faceObs.boundingBox.topRight, faceObs.boundingBox.bottomRight].map({
                convert($0.applying(viewTransform).glVector)
            })
            
            // find anchor
            let anchor: ARFSFaceAnchor
            if let existingAnchor = _faceAnchors[obs.uuid] {
                anchor = existingAnchor
            }
            else {
                anchor = ARFSFaceAnchor()
                _faceAnchors[obs.uuid] = anchor
                newAnchors.append(anchor)
            }
            
            // map landmarks
            let landmark = ARFSFaceLandmarks()
            ARFSFaceLandmarks.Keys.All.forEach({ key in
                guard let region = faceObs.landmarks?.value(forKey: key.visionLandmarkKey) as? VNFaceLandmarkRegion2D
                    else { return }
                let arfsRegion = region.pointsInImageUpsideDown(imageSize: viewportSize).map({
                    convert($0.glVector).sim_vector
                })
                landmark.sampleValues[key] = arfsRegion
            })
            
            // look at
            var lookAt = (point2.worldPosition - point1.worldPosition) * (point3.worldPosition - point1.worldPosition)
            if ((frame.camera.ray.vector3 • lookAt) < 0) {
                lookAt = -lookAt
            }
            anchor.samples.append((
                pos: faceCenter.sim_vector,
                //rot: GLKQuaternion.lookRotation(forward: (vertex[1] - vertex[0]) * (vertex[1] - vertex[2]), up: (vertex[1] - vertex[0])).sim_quaternion
                lookat: (lookAt).sim_vector,
                landmark: landmark
            ))
            anchor.scaleSamples.append(GLKVector3Make((vertex[0] - vertex[1]).length, (vertex[1] - vertex[2]).length, 0.2).sim_vector)
            if let up = landmark.medianLine.fittedLine?.sim_vector {
                anchor.faceLookUp = up
            }
            anchor.face2DBoundingBox = faceObs.boundingBox.applying(viewTransform)
            anchor.faceObservation = faceObs
            anchor.pointClouds = arHitTestResults.map({ $0.worldPosition.sim_vector })
            anchor.point2DClouds = arHitTestResults.map({ $0.projection })
            if anchor.samples.count >= 20 {
                anchor.samples.removeFirst()
                anchor.scaleSamples.removeFirst()
            }
            anchor.lastUpdate = frame.timestamp
            
            
        }
        
        _faceAnchors.filter({ $0.value.lastUpdate < frame.timestamp - 0.5 }).forEach({ (k, v) in
            guard let req = _faceRequests[k] else { return }
            visionRequests = visionRequests.filter({ $0 != req })
            _faceRequests.removeValue(forKey: k)
            NSLog("remove face \(req.inputObservation.uuid)")
        })
        
        _faceAnchors = _faceAnchors.filter({ $0.value.lastUpdate > frame.timestamp - 0.5})
        DispatchQueue.main.async {
            newAnchors.forEach({ self.delegate?.newFaceDidAdd?(self, anchor: $0) })
            self.delegate?.facesDidUpdate?(self, anchors: self.faceAnchors)
        }
        
    }
    
    fileprivate func trackingHandler(request: VNRequest, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        guard let observations = request.results else {
            print("No results")
            return
        }
        
        trackingObservations = observations.flatMap({ $0 as? VNDetectedObjectObservation})
        trackingObservations.forEach({ self._trackingLastUpdate[$0.uuid] = Date().timeIntervalSince1970 })
        visionRequests = visionRequests.filter({ (req) in
            if let r = req as? VNTrackObjectRequest, self._trackingLastUpdate[r.inputObservation.uuid] ?? 0 < Date().timeIntervalSince1970 - 0.5 {
                NSLog("remove face \(r.inputObservation.uuid)")
                return false
            }
            else {
                return true
            }
        })
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
        
        // find new face
        faceObservations.forEach({ obs in
            let existedFace = trackingObservations.filter({ $0.boundingBox.intersects(obs.boundingBox)})
            guard existedFace.count == 0 else { return }
            
            self.addTrackingRequest(faceObj: obs)
        })
    }
    
    fileprivate var _detectionCount: Int = 0
    public func updateDetection() {
        func _updateDetection() {
            guard let pixbuff = (session.currentFrame?.capturedImage) else { return }
            //let image = CIImage(cvPixelBuffer: pixbuff).rotate
            //let content =  CIContext()
            //let cgImage = content.createCGImage(image, from: image.extent)
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixbuff, orientation: UIDevice.current.orientation.cameraOrientation, options: [:])
            
            do {
                try imageRequestHandler.perform(visionRequests)
                updateBinding()
            } catch {
                print(error)
            }
        }
        
        guard Thread.current.isMainThread else {
            DispatchQueue.main.async(execute: updateDetection)
            return
        }
        
        guard _detectionCount == 0 else { return }
        
        _detectionCount += 1
        visionQueue.async {
            _updateDetection()
            DispatchQueue.main.sync {
                self._detectionCount -= 1
            }
        }
    }
}
