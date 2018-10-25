//
//  QRPickerController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 25/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

class QRPickerController: NSObject {
    let imagePickerController = UIImagePickerController()
    
    static var canOpenImagePicker: Bool {
        return UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
    }
    
    override init() {
        super.init()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
    }
}

extension QRPickerController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // TODO: verify the image is a qr code. pass in a delegate the results
    }
}
