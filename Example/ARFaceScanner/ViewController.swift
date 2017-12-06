//
//  ViewController.swift
//  ARFace
//
//  Created by Simon on 10/8/17.
//  Copyright © 2017 zhangy405. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision
import ARFaceScanner
import VideoToolbox
import PureLayout

class HeadNode: SCNNode {
    var leftEye: SCNNode
    var rightEye: SCNNode
    var lip: SCNNode
    
    override init() {
//        let headNode = SCNScene(named: "head.dae")!.rootNode.childNode(withName: "head", recursively: true)!
//        let node = SCNNode()
//        node.addChildNode(headNode)
//        node.position = SCNVector3(x: 0, y: 0, z: 0)
//        headNode.position = SCNVector3(x: 0, y: 0, z: 0)
//        headNode.scale = SCNVector3(0.8, 0.8, 0.8)
//        headNode.eulerAngles = SCNVector3(0, Float.pi * 0.5, Float.pi )
        leftEye = SCNNode()
        leftEye.geometry = SCNSphere(radius: 0.02)
        leftEye.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        var eyeBall = SCNNode()
        eyeBall.geometry = SCNSphere(radius: 0.01)
        //leftEye.addChildNode(eyeBall)
        eyeBall.position = SCNVector3(-0.02, 0, 0)
        eyeBall.geometry?.firstMaterial?.diffuse.contents = UIColor.black
        
        rightEye = SCNNode()
        rightEye.geometry = SCNSphere(radius: 0.02)
        rightEye.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        eyeBall = SCNNode()
        eyeBall.geometry = SCNSphere(radius: 0.01)
        //rightEye.addChildNode(eyeBall)
        eyeBall.position = SCNVector3(-0.02, 0, 0)
        eyeBall.geometry?.firstMaterial?.diffuse.contents = UIColor.black
        
        lip = SCNNode()
        lip.geometry = SCNSphere(radius: 0.02)
        lip.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        
        super.init()
        
        let upDirection = SCNNode()
        upDirection.geometry = SCNCylinder(radius: 0.005, height: 0.3)
        upDirection.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        upDirection.pivot = SCNMatrix4MakeTranslation(0, -0.15, 0)
        
        let rightDirection = SCNNode()
        rightDirection.geometry = SCNCylinder(radius: 0.005, height: 0.3)
        rightDirection.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        rightDirection.pivot = SCNMatrix4MakeTranslation(0, -0.15, 0)
        rightDirection.eulerAngles = SCNVector3Make(0, 0, .pi * 0.5)
        
        let forwardDirection = SCNNode()
        forwardDirection.geometry = SCNCylinder(radius: 0.005, height: 0.3)
        forwardDirection.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        forwardDirection.pivot = SCNMatrix4MakeTranslation(0, -0.15, 0)
        forwardDirection.eulerAngles = SCNVector3Make(.pi * 0.5, 0, 0)
        
        addChildNode(upDirection)
        addChildNode(rightDirection)
        addChildNode(forwardDirection)
        
        addChildNode(leftEye)
        addChildNode(rightEye)
        addChildNode(lip)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class FacePool {
    var pool = [HeadNode]()
    var used = [HeadNode]()
    func request() -> HeadNode {
        if pool.count == 0 {
            pool.append(HeadNode())
        }
        used.append(pool.last!)
        return pool.popLast()!
    }
    
    func release(node: HeadNode) {
        node.removeFromParentNode()
        pool.append(node)
        if let index = used.index(of: node) {
             used.remove(at: index)
        }
    }
    
    func releaseAll() {
        used.forEach({ release(node: $0 )})
    }
}

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, ARFSFaceManagerDelegate {
    // UI
    @IBOutlet var sceneView: ARSCNView!
    var faceHUDView = FaceDectionHUDView(frame: CGRect.zero)
    var lockSwitch: UISwitch!
    // AR2DFaceManager
    var faceManager = ARFSFaceManager()
    var locked = false
    // SceneKit
    let bubbleDepth : Float = 0.01
    var faceTextNodes = [Int: SCNNode]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.automaticallyUpdatesLighting = false
        sceneView.autoenablesDefaultLighting = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        let scene = SCNScene()
        sceneView.scene = scene
   
        view.insertSubview(faceHUDView, aboveSubview: sceneView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapBackground(_:)))
        faceHUDView.addGestureRecognizer(tapGesture)
        
        faceManager.delegate = self
        
        setupUI()
    }
    
    func setupUI() {
        lockSwitch = UISwitch(frame: CGRect.zero)
        lockSwitch.setOn(false, animated: false)
        view.insertSubview(lockSwitch, aboveSubview: faceHUDView)
        lockSwitch.addTarget(self, action: #selector(lockDidChanged(_:)), for: .valueChanged)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        faceHUDView.frame = sceneView.frame
        lockSwitch.frame.origin.y = sceneView.frame.height - 51.0;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.session.run(configuration)
        sceneView.session.delegate = self
        
        faceManager.start(sceneView.session, viewportSize: sceneView.frame.size)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // MARK: - ARSCNViewDelegate
    
    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()
     
     return node
     }
     */
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        faceManager.updateDetection()
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    private func createNewBubbleParentNode(_ text : String) -> SCNNode {
        // Warning: Creating 3D Text is susceptible to crashing. To reduce chances of crashing; reduce number of polygons, letters, smoothness, etc.
        
        // TEXT BILLBOARD CONSTRAINT
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        
        // BUBBLE-TEXT
        let bubble = SCNText(string: text, extrusionDepth: CGFloat(bubbleDepth))
        var font = UIFont(name: "Futura", size: 0.15)
        font = font?.withTraits(traits: .traitBold)
        bubble.font = font
        //bubble.isWrapped = true
        bubble.alignmentMode = kCAAlignmentCenter
        //bubble.containerFrame = CGRect(x: 0, y: 0, width: 1, height: 1 * 5)
        bubble.firstMaterial?.diffuse.contents = UIColor.orange
        bubble.firstMaterial?.specular.contents = UIColor.white
        bubble.firstMaterial?.isDoubleSided = true
        // bubble.flatness // setting this too low can cause crashes.
        bubble.chamferRadius = CGFloat(bubbleDepth)
        
        // BUBBLE NODE
        let (minBound, maxBound) = bubble.boundingBox
        let bubbleNode = SCNNode(geometry: bubble)
        // Centre Node - to Centre-Bottom point
        bubbleNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, bubbleDepth/2)
        // Reduce default text size
        bubbleNode.scale = SCNVector3Make(0.2, 0.2, 0.2)
        
        // CENTRE POINT NODE
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.cyan
        let sphereNode = SCNNode(geometry: sphere)
        
        // BUBBLE PARENT NODE
        let bubbleNodeParent = SCNNode()
        bubbleNodeParent.addChildNode(bubbleNode)
        //bubbleNodeParent.addChildNode(sphereNode)
        bubbleNodeParent.constraints = [billboardConstraint]
        
        return bubbleNodeParent
    }
    
    // MARK: - AR2DFaceManagerDelegate
    var _facePool = FacePool()
    func facesDidUpdate(_ manager: ARFSFaceManager, anchors: [ARFSFaceAnchor]) {
        guard !locked else { return }
        faceHUDView.faceBoxes = anchors.flatMap({ $0.face2DBoundingBox })
       // _facesSpheres.forEach({$0.removeFromParentNode()})
        faceHUDView.debugPoints = []
    
        _facePool.releaseAll()
        
        anchors.forEach { (anchor) in
             guard anchor.sampleCount > 0 else { return }
            
            if let textNode = faceTextNodes[anchor.faceID]{
                var facePos = anchor.facePosition.glk_vector
                
                facePos = facePos - (sceneView.session.currentFrame!.camera.transform.glk_matrix * GLKVector3.right.pointVector4).vector3.normal * 0.2
                textNode.simdPosition = facePos.sim_vector
            }
            else {
                // new face
                addFaceText(anchor: anchor)
            }
            
            //let rotation = SCNQuaternion(anchor.faceOrientation.vector.x, anchor.faceOrientation.vector.y, anchor.faceOrientation.vector.z, anchor.faceOrientation.vector.w)
            let node = self._facePool.request()
            //sphere.firstMaterial?.diffuse.contents = UIColor.green
            //let node = SCNNode(geometry: sphere)
            node.simdPosition = anchor.facePosition
            //node.simdScale = anchor.faceScale
            //print(anchor.faceScale)
            node.simdLook(at: anchor.faceLookAt, up: vector3(0, 1, 0), localFront: (anchor.faceLookAt.glk_vector * vector3(0, 1, 0) .glk_vector).sim_vector )
            //node.simdLook(at: anchor.faceLookAt)
            node.leftEye.simdWorldPosition = anchor.landmarks?.leftEye.first ?? vector3(0, 0, 0)
            node.rightEye.simdWorldPosition = anchor.landmarks?.rightEye.first ?? vector3(0, 0, 0)
            node.lip.simdWorldPosition = anchor.landmarks?.innerLips.first ?? vector3(0, 0, 0)
            sceneView.scene.rootNode.addChildNode(node)

            faceHUDView.debugPoints.append(contentsOf: anchor.point2DClouds)
        }
        
        Set(faceTextNodes.keys).subtracting(anchors.map({ $0.faceID })).forEach({
            faceTextNodes[$0]?.removeFromParentNode()
            faceTextNodes.removeValue(forKey: $0)
        })
    }
    
    func addFaceText(anchor: ARFSFaceAnchor) {
        let pos = anchor.facePosition
        let worldCoord = SCNVector3Make(pos.x, pos.y, pos.z)
        let box = anchor.faceObservation!.boundingBox
        let node: SCNNode = SCNNode()
        // Create image
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(sceneView.session.currentFrame!.capturedImage, nil, &cgImage)
        cgImage = CreateMatchingBackingDataWithImage(imageRef: cgImage, orienation: .left)
        cgImage = cgImage?.cropping(to: box.denomalize(to: CGRect(origin: CGPoint.zero, size: CGSize(width: cgImage!.width, height: cgImage!.height))))
        let image = UIImage(cgImage: cgImage!)
        let facePlane = SCNPlane(width: 0.1, height: 0.1 / image.size.width * image.size.height)
        facePlane.firstMaterial?.diffuse.contents = image
        facePlane.firstMaterial?.lightingModel = .constant
        let faceNode = SCNNode(geometry: facePlane)
        node.addChildNode(faceNode)
        faceNode.position = SCNVector3Make(0, 0.1, 0)
        
        // Create 3D Text
        let textNode : SCNNode = createNewBubbleParentNode("Analyzing...")
        textNode.position = SCNVector3Make(0.1, 0, 0)
        node.addChildNode(textNode)
        
        // TEXT BILLBOARD CONSTRAINT
        let faceConstraint = SCNBillboardConstraint()
        faceConstraint.freeAxes = SCNBillboardAxis.Y
        var facePos = worldCoord
        //facePos.x += 0.2
        node.position = facePos
        node.constraints = [faceConstraint]
        sceneView.scene.rootNode.addChildNode(node)
        
        faceTextNodes[anchor.faceID] = node
        FPPProvider().processFace(image: image, handler: { (text) in
            DispatchQueue.main.async {
                textNode.removeFromParentNode()
                if let text = text {
                    text.components(separatedBy: "\n").enumerated().forEach({ (i, line) in
                        let textNode : SCNNode = self.createNewBubbleParentNode(line)
                        node.addChildNode(textNode)
                        textNode.position = SCNVector3Make(0.1, -(Float(i) * 0.03), 0)
                    })
                }
                else {
                    let textNode : SCNNode = self.createNewBubbleParentNode(text ?? "Face")
                    node.addChildNode(textNode)
                    textNode.position = SCNVector3Make(0.1, 0, 0)
                }
            }
        })
    }
    
    // MARK: - Action
    @objc func didTapBackground(_ sender: UIGestureRecognizer) {
        let anchors = faceManager.faceAnchors
        
        anchors.forEach { (anchor) in
            

        }
    }
    
    @objc func lockDidChanged(_ sender: UISwitch) {
        locked = sender.isOn
    }
}

