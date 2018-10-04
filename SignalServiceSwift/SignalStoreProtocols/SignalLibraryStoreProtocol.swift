//
//  SignalLibraryStoreProtocol.swift
//  SignalServiceSwift
//
//  Created by Igor Ranieri on 25.04.18.
//

import Foundation

// Catch-all protocol that incorporates all individual store types.
public protocol SignalLibraryStoreProtocol: SignalSessionStoreProtocol, SignalPreKeyStoreProtocol, SignalSignedPreKeyStoreProtocol, SignalIdentityKeyStoreProtocol, SignalSenderKeyStoreProtocol {

    var delegate: SignalLibraryStoreDelegate { get }

    var context: SignalContext! { get set }
}
