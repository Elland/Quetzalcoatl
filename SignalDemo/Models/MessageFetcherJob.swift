//
//  MessageFetcherJob.swift
//  Signal
//
//  Created by Igor Ranieri on 12.10.18.
//  Copyright © 2018 elland.me. All rights reserved.
//

import UIKit
import Teapot

public  final class MessageFetcherJob: NSObject {
    enum MessageResponseKeys {
        static let messages = "messages"
        static let more = "more"
        static let type = "type"
        static let relay = "relay"
        static let timestamp = "timestamp"
        static let source = "source"
        static let sourceDevice = "sourceDevice"
        static let message = "message"
        static let content = "content"
    }

    private let teapot: Teapot
    private let username: String
    private let password: String
    private let messageReceiver: SignalMessageManager

    public init(teapot: Teapot, username: String, password: String, messageManager: SignalMessageManager) {
        self.teapot = teapot
        self.password = password
        self.username = username
        self.messageReceiver = messageManager
    }

    public func run() {
        self.fetchUndeliveredMessages { [weak self] envelopes, more, _ in
            guard let strongSelf = self else { return }

            for envelope in envelopes {
                _ = strongSelf.messageReceiver.decryptCiphertextEnvelope(envelope)
                strongSelf.acknowledgeDelivery(envelope: envelope)
            }

            if more {
                return strongSelf.run()
            }
        }
    }

    private func parseMessagesResponse(_ response: [String: Any]?) -> (envelopes: [Signalservice_Envelope], more: Bool)? {
        guard let response = response,
        let messages = response[MessageResponseKeys.messages] as? [[String: Any]]
        else { return nil }

        let moreMessages = { () -> Bool in
            return response[MessageResponseKeys.more] as? Bool ?? false
        }()


        let envelopes = messages.map({ r in self.buildEnvelope(messageDict: r) }).filter({ $0 != nil }).map({ $0! })

        return (
            envelopes: envelopes,
            more: moreMessages
        )
    }

    private func buildEnvelope(messageDict: [String: Any]) -> Signalservice_Envelope? {
        guard let typeInt = messageDict[MessageResponseKeys.type] as? Int else { return nil }
        guard let type = Signalservice_Envelope.TypeEnum(rawValue: typeInt) else { return nil }

        var envelope = Signalservice_Envelope()
        envelope.type = type

        if let relay = messageDict[MessageResponseKeys.relay] as? String {
            envelope.relay = relay
        }

        guard let timestamp = messageDict[MessageResponseKeys.timestamp] as? UInt64 else { return nil }
        envelope.timestamp = timestamp

        guard let source = messageDict[MessageResponseKeys.source] as? String else { return nil }
        envelope.source = source

        guard let sourceDevice = messageDict[MessageResponseKeys.sourceDevice] as? UInt32 else { return nil }
        envelope.sourceDevice = sourceDevice

        if let encodedContent = messageDict[MessageResponseKeys.content] as? String {
            if let content = Data(base64Encoded: encodedContent) {
                envelope.content = content
            }
        }

        return envelope
    }

    private func fetchUndeliveredMessages(completion: @escaping ([Signalservice_Envelope], Bool, Error?) -> Void) {
        let path = "/v1/messages"
        let headerFields = self.teapot.basicAuthenticationHeader(username: username, password: password)

        self.teapot.get(path, headerFields: headerFields) { result in
            switch result {
            case let .success(params, response):
                guard let (envelopes, more) = self.parseMessagesResponse(params?.dictionary) else {
                    return completion([], false, nil)
                }

                completion(envelopes, more, nil)
            case .failure(_, _, _):
                completion([], false, nil)
            }
        }
    }

    private func acknowledgeDelivery(envelope: Signalservice_Envelope) {
        let path = String(format: "/v1/messages/%@/%llu", envelope.source, envelope.timestamp)

        self.teapot.delete(path) { _ in }
    }
}
