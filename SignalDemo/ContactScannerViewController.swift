//
//  CreateChatControllerViewController.swift
//  Signal
//
//  Created by Igor Ranieri on 10.10.18.
//  Copyright © 2018 elland.me. All rights reserved.
//

import UIKit
import CameraScanner

class ContactScannerViewController: ScannerViewController {
    required init(instructions: String, types: [MetadataObjectType], startScanningAtLoad startsScanning: Bool, showSwitchCameraButton showSwitch: Bool, showTorchButton showTorch: Bool, alertIfUnavailable: Bool) {
        super.init(instructions: instructions, types: types, startScanningAtLoad: startsScanning, showSwitchCameraButton: showSwitch, showTorchButton: showTorch, alertIfUnavailable: alertIfUnavailable)

        self.hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var importImageButton: UIBarButtonItem = {
        return UIBarButtonItem(title: "Import QR code", style: .plain, target: self, action: #selector(self.didPressImportImageButton))
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.toolbar.items = []
        self.toolbar.isHidden = true
        self.navigationItem.rightBarButtonItem = self.importImageButton
    }

    @objc private func didPressImportImageButton() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self

        self.present(imagePickerController, animated: true)
    }
}

extension ContactScannerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        defer { picker.dismiss(animated: true) }
        guard let image = info[.originalImage] as? UIImage else { return }

        guard let feature = QRCodeDetector.detect(from: image),
            let content = feature.messageString
            else { return }

        self.delegate?.scannerViewController(self, didScanResult: content)
    }
}

