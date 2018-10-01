//
//  MessagesViewController+Keyboard.swift
//  SignalServiceSwift
//
//  Created by Igor Ranieri on 01.10.18.
//  Copyright © 2018 Bakken&Bæck. All rights reserved.
//

import UIKit

extension MessagesViewController {
    
    internal func addKeyboardObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MessagesViewController.handleKeyboardDidChangeState(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MessagesViewController.handleTextViewDidBeginEditing(_:)),
                                               name: UITextView.textDidBeginEditingNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MessagesViewController.adjustScrollViewInset),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }

    internal func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UITextView.textDidBeginEditingNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    // MARK: - Notification Handlers

    @objc
    private func handleTextViewDidBeginEditing(_ notification: Notification) {
//        if self.scrollsToBottomOnKeybordBeginsEditing {
//            guard let inputTextView = notification.object as? InputTextView, inputTextView === messageInputBar.inputTextView else { return }
//            messagesCollectionView.scrollToBottom(animated: true)
//        }
    }

    @objc
    private func handleKeyboardDidChangeState(_ notification: Notification) {
//        guard let keyboardEndFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
//
////        guard !self.isBeingDismissed else { return }
//
//        let newBottomInset = view.frame.height - keyboardEndFrame.minY - iPhoneXBottomInset
//
//        let differenceOfBottomInset = newBottomInset - self.messagesViewBottomInset
//
//        if self.maintainPositionOnKeyboardFrameChanged && differenceOfBottomInset != 0 {
//            let contentOffset = CGPoint(x: messagesCollectionView.contentOffset.x, y: messagesCollectionView.contentOffset.y + differenceOfBottomInset)
//            messagesCollectionView.setContentOffset(contentOffset, animated: false)
//        }
//
//        messageCollectionViewBottomInset = newBottomInset
    }

    @objc
    internal func adjustScrollViewInset() {
        if #available(iOS 11.0, *) {
            // No need to add to the top contentInset
        } else {
            let navigationBarInset = navigationController?.navigationBar.frame.height ?? 0
            let statusBarInset: CGFloat = UIApplication.shared.isStatusBarHidden ? 0 : 20
            let topInset = navigationBarInset + statusBarInset
            self.tableView.contentInset.top = topInset
            self.tableView.scrollIndicatorInsets.top = topInset
        }
    }

    // MARK: - Helpers

    internal var keyboardOffsetFrame: CGRect {
        guard let inputFrame = inputAccessoryView?.frame else { return .zero }
        return CGRect(origin: inputFrame.origin, size: CGSize(width: inputFrame.width, height: inputFrame.height - iPhoneXBottomInset))
    }

    /// On the iPhone X the inputAccessoryView is anchored to the layoutMarginesGuide.bottom anchor
    /// so the frame of the inputAccessoryView is larger than the required offset
    /// for the MessagesCollectionView.
    ///
    /// - Returns: The safeAreaInsets.bottom if its an iPhoneX, else 0
    private var iPhoneXBottomInset: CGFloat {
        if #available(iOS 11.0, *) {
            guard UIScreen.main.nativeBounds.height == 2436 else { return 0 }
            return view.safeAreaInsets.bottom
        }
        return 0
    }
}
