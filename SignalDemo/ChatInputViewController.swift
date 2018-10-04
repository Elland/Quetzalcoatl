//
//  ChatInputViewController.swift
//  Mercury
//
//  Created by Igor Ranieri on 26.09.18.
//  Copyright © 2018 Bakken & Bæck. All rights reserved.
//

import UIKit

protocol ChatInputViewControllerDelegate: class {
    func didSendMessage(_ text: String)
}

class ChatInputViewController: SLKTextViewController {
    var searchResults: [String] = []
    var usernames: [String] = []

    weak var delegate: ChatInputViewControllerDelegate?

    init(usernames: [String], delegate: ChatInputViewControllerDelegate) {
        super.init(tableViewStyle: .plain)!

        self.delegate = delegate
        self.usernames = usernames
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.autoCompletionView.register(AutoCompleteTableViewCell.self)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.removeFromSuperview()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.removeFromSuperview()
    }
    
    override func didChangeAutoCompletionPrefix(_ prefix: String, andWord word: String) {
        self.searchResults.removeAll()

        if prefix == "@", !word.isEmpty {
            self.searchResults = self.usernames.filter({ name -> Bool in return name.hasPrefix(word) })
        }

        let shouldShow = !self.searchResults.isEmpty
        self.showAutoCompletionView(shouldShow)
    }

    override func didPressRightButton(_ sender: Any?) {
        // Send a message
        self.delegate?.didSendMessage(self.textView.text)
        super.didPressRightButton(sender)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.autoCompletionView {
            return self.searchResults.count
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(AutoCompleteTableViewCell.self, for: indexPath)
        let text = "@\(self.searchResults[indexPath.row])"

        cell.indexPath = indexPath
        cell.titleLabel.text = text

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }

    override func heightForAutoCompletionView() -> CGFloat {
        let cellHeight = self.autoCompletionView.delegate!.tableView!(self.autoCompletionView, heightForRowAt: IndexPath(row: 0, section: 0))

        return CGFloat(self.searchResults.count) * cellHeight
    }
}
