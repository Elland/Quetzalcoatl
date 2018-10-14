//
//  ContactsListViewController.swift
//  Signal
//
//  Created by Igor Ranieri on 13.10.18.
//  Copyright © 2018 elland.me. All rights reserved.
//

import UIKit
import Quetzalcoatl
import CameraScanner

class ContactCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.selectedBackgroundView = UIView()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.accessoryType = selected ? .checkmark : .none
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ContactsDataSource: NSObject, UITableViewDataSource {
    unowned var tableView: UITableView

    var contacts: [Profile] {
        return SessionManager.shared.contactManager.profiles
    }

    init(tableView: UITableView) {
        self.tableView = tableView

        super.init()

        self.tableView.register(ContactCell.self)
        self.tableView.dataSource = self
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.contacts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(ContactCell.self, for: indexPath)
        let contact = self.contacts[indexPath.row]

        cell.textLabel?.text = contact.nameOrDisplayName
        cell.detailTextLabel?.text = contact.displayUsername
        cell.imageView?.image = AvatarManager.cachedAvatar(for: contact.id)
        cell.imageView?.layer.cornerRadius = 22
        cell.imageView?.layer.masksToBounds = true

        return cell
    }
}

class ContactsListViewController: UIViewController {
    private(set) var contactsDataSource: ContactsDataSource!

    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .plain)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.separatorStyle = .none
        view.delegate = self

        return view
    }()

    let createChat: Bool

    init(createChat: Bool) {
        self.createChat = createChat

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if self.createChat {
            let createChatButton = UIBarButtonItem(title: "Create chat", style: .plain, target: self, action: #selector(self.didTapAddContact))
            createChatButton.isEnabled = false
            self.navigationItem.rightBarButtonItem = createChatButton
        } else {
            let addContatButton = UIBarButtonItem(title: "Add contact", style: .plain, target: self, action: #selector(self.didTapAddContact))
            self.navigationItem.rightBarButtonItem = addContatButton
        }

        self.title = "Contacts"
        self.contactsDataSource = ContactsDataSource(tableView: self.tableView)

        self.view.addSubview(self.tableView)
        self.tableView.allowsMultipleSelection = self.createChat

        self.tableView.edgesToSuperview()
        self.tableView.reloadData()

        // TODO: coalesce
        NotificationCenter.default.addObserver(forName: ContactManager.displayNameDidUpdateNotification, object: nil, queue: .main) { notif in
            self.tableView.reloadData()
        }
        NotificationCenter.default.addObserver(forName: ContactManager.didAddContactNotification, object: nil, queue: .main) { notif in
            self.tableView.reloadData()
        }
        NotificationCenter.default.addObserver(forName: AvatarManager.avatarDidUpdateNotification, object: nil, queue: .main) { notif in
            self.tableView.reloadData()
        }
    }

    @objc private func didTapAddContact() {
        if self.createChat {
            guard let selectedRows = self.tableView.indexPathsForSelectedRows else { return }
            let contacts = selectedRows.map({ indexPath -> Profile in return self.contactsDataSource.contacts[indexPath.row] })

            if contacts.count == 1, let contact = contacts.first {
                _ = SessionManager.shared.quetzalcoatl.store.fetchOrCreateChat(with: contact.id)
            } else {
                let ids = [Profile.current!.id] + contacts.map({$0.id})
                let chat = SessionManager.shared.quetzalcoatl.store.fetchOrCreateChat(with: ids)
                chat.name = contacts.map({$0.nameOrDisplayName}).joined(separator: ", ")
                SessionManager.shared.quetzalcoatl.sendInitialGroupMessage(in: chat)
            }

            self.navigationController?.popToViewController(self, animated: true)
            self.dismiss(animated: true)

        } else {
            let scannerController = ContactScannerViewController(instructions:  "", types: [.qrCode], startScanningAtLoad: true, showSwitchCameraButton: false, showTorchButton: false, alertIfUnavailable: true)

            scannerController.delegate = self
            self.navigationController?.pushViewController(scannerController, animated: true)
        }
    }

    @objc func resign() {
        self.dismiss(animated: true)
    }
}

extension ContactsListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.createChat {
            self.navigationItem.rightBarButtonItem?.isEnabled = !(self.tableView.indexPathsForSelectedRows?.isEmpty ?? true)
        } else {
            let contact = self.contactsDataSource.contacts[indexPath.row]
            let contactViewController = ContactViewController.controller(with: contact.id)

            self.navigationController?.pushViewController(contactViewController, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if self.createChat {
            self.navigationItem.rightBarButtonItem?.isEnabled = !(self.tableView.indexPathsForSelectedRows?.isEmpty ?? true)
        }
    }
}

extension ContactsListViewController: ScannerViewControllerDelegate {
    func scannerViewController(_ controller: ScannerViewController, didScanResult result: String) {
        guard let url = URL(string: result),
            url.scheme == "quetzalcoatl",
            let id = url.host
            else {
                controller.startScanning()
                return
        }

        self.navigationController?.popToViewController(self, animated: true)
        let contactViewController = ContactViewController.controller(with: id)
        self.navigationController?.pushViewController(contactViewController, animated: true)
    }

    func scannerViewControllerDidCancel(_ controller: ScannerViewController) {
        self.navigationController?.popViewController(animated: true)
    }
}
