//
//  QRViewController.swift
//  KinEcosystem
//
//  Created by Corey Werner on 18/10/2018.
//  Copyright © 2018 Kik Interactive. All rights reserved.
//

import UIKit

@available(iOS 9.0, *)
class QRViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var reminderImageView: UIImageView!
    @IBOutlet weak var reminderTitleLabel: UILabel!
    @IBOutlet weak var reminderDescriptionLabel: UILabel!
    @IBOutlet weak var continueButton: RoundButton!
    
    private let qrString: String
    
    init(qrString: String) {
        self.qrString = qrString
        super.init(nibName: "QRViewController", bundle: Bundle.ecosystem)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        loadViewIfNeeded()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = "kinecosystem_backup_qr_title".localized()
        titleLabel.textColor = .kinPrimaryBlue
        descriptionLabel.text = "kinecosystem_backup_qr_description".localized()
        descriptionLabel.textColor = .kinBlueGreyTwo
        qrImageView.image = generateQRImage(from: qrString, for: qrImageView.bounds.size)
        reminderImageView.tintColor = .kinWarningRed
        reminderTitleLabel.text = "kinecosystem_backup_reminder_title".localized()
        reminderTitleLabel.textColor = .kinWarningRed
        reminderDescriptionLabel.text = "kinecosystem_backup_reminder_description".localized()
        reminderDescriptionLabel.textColor = .kinWarningRed
        continueButton.setTitle("kinecosystem_backup_qr_continue".localized(), for: .normal)
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.backgroundColor = .kinPrimaryBlue
    }
    
    /**
     Create a QR image from a string.
     
     - Parameter string: The string used in the QR image.
     - Parameter size: The size of the `UIImageView` that will display the image.
     - Returns: A QR image.
    */
    private func generateQRImage(from string: String, for size: CGSize? = nil) -> UIImage? {
        let data = string.data(using: .isoLatin1)
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else {
            return nil
        }
        
        let transform: CGAffineTransform
        
        if let size = size {
            let scaleX = size.width / outputImage.extent.width
            let scaleY = size.height / outputImage.extent.height
            transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        }
        else {
            transform = CGAffineTransform(scaleX: 10, y: 10)
        }
        
        return UIImage(ciImage: outputImage.transformed(by: transform))
    }
}
