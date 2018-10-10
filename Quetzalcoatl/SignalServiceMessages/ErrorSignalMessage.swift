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

    public init(kind: Kind, senderId: String, recipientId: String, chatId: String, store: SignalServiceStore?) {
        self.kind = kind

        super.init(recipientId: recipientId, senderId: senderId, chatId: chatId, body: "", store: store)
    }

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
