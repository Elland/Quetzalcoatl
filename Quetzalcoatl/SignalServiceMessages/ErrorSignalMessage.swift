//
//  ErrorSignalMessage.swift
//  Quetzalcoatl
//
//  Created by Igor Ranieri on 10.10.18.
//  Copyright © 2018 elland.me. All rights reserved.
//

import UIKit

public class ErrorSignalMessage: OutgoingSignalMessage {
    public enum Kind: Int32 {
        case noSession
        case wrongTrustedIdentityKey // DEPRECATED: We no longer create TSErrorMessageWrongTrustedIdentityKey, but
        // persisted legacy messages could exist indefinitly.
        case invalidKeyException
        case missingKeyId // unused
        case invalidMessage
        case duplicateMessage // unused
        case invalidVersion
        case nonBlockingIdentityChange
        case unknownContactBlockOffer
        case groupCreationFailed
    }

    public let kind: Kind

    override var isVisible: Bool {
        return [.noSession, .invalidKeyException, .invalidMessage].contains(self.kind)
    }

    public init(kind: Kind, senderId: String, recipientId: String, chatId: String, store: SignalServiceStore?) {
        self.kind = kind

        let body: String

        switch kind {
        case .duplicateMessage:
            body = "ERROR_MESSAGE_DUPLICATE_MESSAGE"
        case .groupCreationFailed:
            body = "GROUP_CREATION_FAILED"
        case .invalidKeyException:
            body = "ERROR_MESSAGE_INVALID_KEY_EXCEPTION"
        case .invalidMessage:
            body = "ERROR_MESSAGE_INVALID_MESSAGE"
        case .invalidVersion:
            body = "ERROR_MESSAGE_INVALID_VERSION"
        case .nonBlockingIdentityChange:
            body = "ERROR_MESSAGE_NON_BLOCKING_IDENTITY_CHANGE_FORMAT"
        case .noSession:
            body = "ERROR_MESSAGE_NO_SESSION"
        case .unknownContactBlockOffer:
            body = "UNKNOWN_CONTACT_BLOCK_OFFER"
        case .wrongTrustedIdentityKey:
            body = "ERROR_MESSAGE_WRONG_TRUSTED_IDENTITY_KEY"
        case .missingKeyId:
            body = "ERROR_MESSAGE_MISSING_KEY_ID"
        }

        super.init(recipientId: recipientId, senderId: senderId, chatId: chatId, body: body, store: store)
    }

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
