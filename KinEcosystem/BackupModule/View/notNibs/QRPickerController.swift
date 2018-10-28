//
//  QRPickerController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 25/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

protocol QRPickerControllerDelegate: NSObjectProtocol {
    func qrPickerControllerDidComplete(_ controller: QRPickerController, with qrString: String?)
}

class QRPickerController: NSObject {
    weak var delegate: QRPickerControllerDelegate?
    
    let imagePickerController = UIImagePickerController()
    
    static var canOpenImagePicker: Bool {
        return UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
    }
    
    override init() {
        super.init()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
    }
    
    deinit {
        print("|||")
    }
}

extension QRPickerController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        delegate?.qrPickerControllerDidComplete(self, with: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage, let qrString = QR.decode(image: image) {
            delegate?.qrPickerControllerDidComplete(self, with: qrString)
        }
        else {
            // TODO: get correct copy
            let title = "QR not recognized".localized()
            let message = "A QR code could not be detected in the image.".localized()
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "kinecosystem_ok".localized(), style: .cancel))
            imagePickerController.present(alertController, animated: true)
            
            // ???:
            // if the image picker dismisses automatically then pass the did complete with no image here
            // otherweise maybe present an alert saying its not a qr coded image..?
        }
    }
}
