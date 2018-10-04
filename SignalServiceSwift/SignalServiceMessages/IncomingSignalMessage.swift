//
//  IncomingSignalMessage.swift
//  SignalServiceSwift
//
//  Created by Igor Ranieri on 18.04.18.
//

/// Our base incoming message.
public class IncomingSignalMessage: SignalMessage {
    public var isRead: Bool = false

    public var isSent: Bool = false

    enum CodingKeys: String, CodingKey {
        case isRead
        case isSent
        case body,
            chatId,
            uniqueId,
            timestamp,
            attachmentPointerIds,
            senderId
    }

    public init(body: String, senderId: String, chatId: String, timestamp: UInt64, store: SignalServiceStore?) {
        super.init(body: body, senderId: senderId, chatId: chatId, store: store)

        self.timestamp = timestamp
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.isRead = try container.decode(Bool.self, forKey: .isRead)
        self.isSent = try container.decode(Bool.self, forKey: .isSent)

        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.isRead, forKey: CodingKeys.isRead)
        try container.encode(self.isSent, forKey: CodingKeys.isSent)

        try super.encode(to: encoder)
    }
}
