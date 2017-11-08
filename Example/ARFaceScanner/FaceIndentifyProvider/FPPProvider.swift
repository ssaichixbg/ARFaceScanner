//
//  FPPProvider.swift
//  ARFace
//
//  Created by Simon on 10/18/17.
//  Copyright © 2017 zhangy405. All rights reserved.
//

import UIKit
import Alamofire

class FPPProvider: NSObject, FaceProvider {
    let apiKey = ""
    let apiSec = ""
    enum URL: String {
        case detect = "https://api-us.faceplusplus.com/facepp/v3/detect"
    }
    
    func processFace(image: UIImage, handler: @escaping (String?) -> ()) {
        guard let imageData = UIImageJPEGRepresentation(image, 1.0) else {
            handler(nil)
            return
        }
        
        let base64Data = imageData.base64EncodedString(options: .lineLength64Characters)
        let parameters: Parameters = [
            "api_key": apiKey,
            "api_secret": apiSec,
            "image_base64": base64Data,
            "return_attributes": "gender,age,smiling,glass,emotion,beauty,ethnicity,skinstatus"
            
        ]
        Alamofire.request(URL.detect.rawValue, method: .post, parameters: parameters).responseJSON { (response) in
            guard let json = response.result.value as? [String: Any] else {
                handler(nil)
                return
            }
            
            guard let faces = json["faces"] as? [[String: Any]], !faces.isEmpty else {
                handler(nil)
                return
            }
            
            let face = faces.first!
            let attributes = face["attributes"] as! [String: Any]
            
            let gender = attributes["gender"] as! [String: String]
            let age = attributes["age"] as! [String: Int]
            let glass = attributes["glass"] as! [String: String]
            let beauty = (attributes["beauty"] as! [String: Any])["male_score"] as! NSNumber
            
            handler([
                "Gender: \(gender["value"]!)",
                "Age: \(age["value"]!)",
                "Glasses: \(glass["value"]!)",
                "Beauty: \(beauty.intValue)"
                ].joined(separator: "\n"))
        }
        
    }
}

