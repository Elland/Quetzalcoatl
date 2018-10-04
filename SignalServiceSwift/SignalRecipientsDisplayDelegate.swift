//
//  SignalRecipientsDelegate.swift
//  SignalServiceSwift
//
//  Created by Igor Ranieri on 26.04.18.
//

public protocol SignalRecipientsDisplayDelegate {
    func image(for address: String) -> UIImage?
    func displayName(for address: String) -> String
}
