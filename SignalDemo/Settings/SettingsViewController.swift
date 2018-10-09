//
//  SettingsViewController.swift
//  Signal
//
//  Created by Igor Ranieri on 09.10.18.
//  Copyright © 2018 elland.me. All rights reserved.
//

import UIKit
import SweetUIKit

class SettingsDataSource: NSObject {
    unowned var tableView: UITableView

    init(tableView: UITableView) {
        self.tableView = tableView

        super.init()

        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
}

extension SettingsDataSource: UITableViewDelegate {
    
}

extension SettingsDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return  UITableViewCell()
    }
}

class SettingsViewController: UIViewController {
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var usernameTextField: UITextField!
    @IBOutlet private weak var separatorView: UIView!

    static func instantiate() -> UIViewController {
        return UIStoryboard(name: String(describing: self), bundle: nil).instantiateInitialViewController()!
    }

    let idClient = IDAPIClient()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.updateUser))

        self.setupView()
    }

    private func setupView() {
        guard let profile = Profile.current else { return }

        self.avatarImageView.layer.cornerRadius = self.avatarImageView.bounds.width / 2

        AvatarManager.avatar(at: profile.avatar) { image in
            self.avatarImageView.image = image ?? Blockies(seed: profile.id, scale: Int(10.0 * UIScreen.main.scale)).createImage()
        }

        self.nameTextField.text = profile.name
        self.usernameTextField.text = profile.username
    }

    @objc private func updateUser() {
        guard let _profile = Profile.current else { fatalError("Cant update user if none present") }
        var profile = _profile
        
        profile.username = (self.usernameTextField.text ?? profile.username).trimmingCharacters(in: .whitespacesAndNewlines)
        profile.name = (self.nameTextField.text ?? profile.name)?.trimmingCharacters(in: .whitespacesAndNewlines)

        self.idClient.updateUser(userDictionary: profile.dictionary!, cereal: profile.cereal) {
            Profile.current = profile
        }
    }

    @IBAction func didTapDismissKeyboardGesture(_ sender: UITapGestureRecognizer) {
        if sender.state == .recognized {
            self.usernameTextField.resignFirstResponder()
            self.nameTextField.resignFirstResponder()
        }
    }
}
