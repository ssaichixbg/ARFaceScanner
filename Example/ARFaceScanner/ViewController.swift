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

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, AR2DFaceManagerDelegate {
    // UI
    @IBOutlet var sceneView: ARSCNView!
    var faceHUDView = FaceDectionHUDView(frame: CGRect.zero)
    
    // AR2DFaceManager
    var faceManager = AR2DFaceManager()
    
    // SceneKit
    let bubbleDepth : Float = 0.01
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.automaticallyUpdatesLighting = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        let scene = SCNScene()
        sceneView.scene = scene
   
        view.insertSubview(faceHUDView, aboveSubview: sceneView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapBackground(_:)))
        faceHUDView.addGestureRecognizer(tapGesture)
        
        faceManager.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        faceHUDView.frame = sceneView.frame
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.session.run(configuration)
        sceneView.session.delegate = self
        
        faceManager.start(sceneView.session)
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
    func facesDidUpdate(_ manager: AR2DFaceManager, anchors: [AR2DFaceAnchor]) {
        faceHUDView.faceBoxes = anchors.flatMap({ $0.faceObservation?.boundingBox })
    }
    
    // MARK: - Action
    @objc func didTapBackground(_ sender: UIGestureRecognizer) {
        let anchors = faceManager.faceAnchors
        
        anchors.forEach { (anchor) in
            let pos = anchor.ARPosition
            let worldCoord = SCNVector3Make(pos.x, pos.y, pos.z)
            let box = anchor.faceObservation!.boundingBox
            
            // Create image
            // TEXT BILLBOARD CONSTRAINT
            let faceConstraint = SCNBillboardConstraint()
            faceConstraint.freeAxes = SCNBillboardAxis.Y
            let snapShot =  sceneView.snapshot()
            let cgImage = snapShot.cgImage!.cropping(to: box.denomalize(to: CGRect(origin: CGPoint.zero, size: snapShot.size)))!
            let image = UIImage(cgImage: cgImage)
            let facePlane = SCNPlane(width: 0.1, height: 0.1 / image.size.width * image.size.height)
            facePlane.firstMaterial?.diffuse.contents = image
            facePlane.firstMaterial?.lightingModel = .constant
            let faceNode = SCNNode(geometry: facePlane)
            var facePos = worldCoord
            facePos.y += 0.1
            faceNode.position = facePos
            faceNode.constraints = [faceConstraint]
            sceneView.scene.rootNode.addChildNode(faceNode)
            
            // Create 3D Text
            let node : SCNNode = createNewBubbleParentNode("Analyzing...")
            sceneView.scene.rootNode.addChildNode(node)
            node.position = worldCoord
            
            FPPProvider().processFace(image: image, handler: { (text) in
                DispatchQueue.main.async {
                    node.removeFromParentNode()
                    if let text = text {
                        text.components(separatedBy: "\n").enumerated().forEach({ (i, line) in
                            let node : SCNNode = self.createNewBubbleParentNode(line)
                            self.sceneView.scene.rootNode.addChildNode(node)
                            var pos = worldCoord
                            pos.y -= (Float(i) * 0.03)
                            node.position = pos
                        })
                    }
                    else {
                        let node : SCNNode = self.createNewBubbleParentNode(text ?? "Face")
                        self.sceneView.scene.rootNode.addChildNode(node)
                        node.position = worldCoord
                    }
                }
            })

        }
    }
}

