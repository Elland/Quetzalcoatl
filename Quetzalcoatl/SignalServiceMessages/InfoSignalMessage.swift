//
//  InfoSignalMessage.swift
//  Quetzalcoatl
//
//  Created by Igor Ranieri on 25.04.18.
//

import Foundation

/// Metadata message. Used to indicate updates to a chat, such as membership change, group rename, and so on.
public class InfoSignalMessage: SignalMessage {
    public enum MessageType: Int, Codable {
        case sessionDidEnd
        case userNotRegistered
        case unsupportedMessage // obsolete?
        case groupUpdate
        case groupQuit
        case disappearingMessagesUpdate
        case addToContactsOffer
        case verificationStateChange
        case addUserToProfileWhitelistOffer
        case addGroupToProfileWhitelistOffer
    }

    enum CodingKeys: String, CodingKey {
        case messageType
        case customMessage
        case additionalInfo
        case body,
            chatId,
            uniqueId,
            timestamp,
            attachmentPointerIds,
            senderId
    }

    public var messageType: MessageType

    /// Localised custom message to be displayed inside chat.
    public var customMessage: String

    /// Additional info used to expand on the custom message.
    public var additionalInfo: String

    public init(senderId: String, chatId: String, messageType: MessageType, customMessage: String = "", additionalInfo: String? = nil, store: SignalServiceStore?) {
        self.customMessage = customMessage
        self.additionalInfo = additionalInfo ?? ""
        self.messageType = messageType

        super.init(body: "", senderId: senderId, chatId: chatId, store: store)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.customMessage = try container.decode(String.self, forKey: .customMessage)
        self.additionalInfo = try container.decode(String.self, forKey: .additionalInfo)
        self.messageType = try container.decode(MessageType.self, forKey: .messageType)

        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.customMessage, forKey: .customMessage)
        try container.encode(self.additionalInfo, forKey: .additionalInfo)
        try container.encode(self.messageType, forKey: .messageType)

        try super.encode(to: encoder)
    }
}
