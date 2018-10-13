//
//  ContactViewController.swift
//  Signal
//
//  Created by Igor Ranieri on 13.10.18.
//  Copyright © 2018 elland.me. All rights reserved.
//

import UIKit

class ContactViewController: UIViewController {
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!

    let idClient = IDAPIClient()

    var contact: Profile?

    var id: String = ""

    static func controller(with id: String) -> ContactViewController {
        let vc = UIStoryboard(name: "ContactViewController", bundle: nil).instantiateInitialViewController() as! ContactViewController

        vc.id = id
        
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let contact = SessionManager.shared.contactManager.profile(for: self.id) {
            self.contact = contact
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Remove contact", style: .plain, target: self, action: #selector(self.addContact))
            self.setupView(contact)
            
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add contact", style: .plain, target: self, action: #selector(self.addContact))

            self.idClient.findUserWithId(self.id) { contact in
                if let contact = contact {
                    DispatchQueue.main.async {
                        self.setupView(contact)
                    }
                }
            }
        }
    }

    func setupView(_ contact: Profile) {
        self.contact = contact
        self.displayNameLabel.text = contact.nameOrDisplayName
        self.usernameLabel.text = contact.displayUsername

        AvatarManager.avatar(for: contact.id, at: contact.avatar, { image in
            self.avatarImageView.image = image
        })
    }

    @objc private func addContact() {
        guard let contact = self.contact else { fatalError() }
        SessionManager.shared.persistenceStore.storeContact(contact)
    }
}
