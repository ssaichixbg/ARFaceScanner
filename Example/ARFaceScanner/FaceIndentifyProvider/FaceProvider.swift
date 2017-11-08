//
//  FaceProvider.swift
//  ARFace
//
//  Created by Simon on 10/18/17.
//  Copyright © 2017 zhangy405. All rights reserved.
//

import UIKit

protocol FaceProvider {
    func processFace(image: UIImage, handler:  @escaping(String?)->())
}

