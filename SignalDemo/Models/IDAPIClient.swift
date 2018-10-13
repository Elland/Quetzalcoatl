//
//  IDAPIClient.swift
//  Quetzalcoatl
//
//  Created by Igor Ranieri on 04.10.18.
//

import Teapot
import EtherealCereal

enum UserRegisterStatus: Int {
    case existing = 0,
    registered,
    failed
}

final class IDAPIClient {
    private var teapot: Teapot

    var baseURL: URL {
        return self.teapot.baseURL
    }

    init() {
        self.teapot = Teapot(baseURL: URL(string: "https://identity.internal.service.toshi.org")!)
    }

    func fetchTimestamp(_ completion: @escaping ((_ timestamp: String) -> Void)) {
        self.teapot.get("/v1/timestamp") { result in
            switch result {
            case .success(let json, let response):
                guard response.statusCode == 200 else { fatalError("Could not retrieve timestamp from chat service.") }
                guard let json = json?.dictionary else { fatalError("JSON dictionary not found in payload") }
                guard let timestamp = json["timestamp"] as? Int else { fatalError("Timestamp not found in json payload or not an integer.") }

                completion(String(timestamp))
            case .failure(_, _, let error):
                NSLog(error.localizedDescription)
            }
        }
    }

    func registerUser(with cereal: EtherealCereal, completion: @escaping ((_ userRegisterStatus: UserRegisterStatus) -> Void)) {
        self.fetchTimestamp { timestamp in
            let path = "/v2/user"
            let parameters = [
                "payment_address": cereal.address
            ]

            let payloadData = try! JSONSerialization.data(withJSONObject: parameters, options: [])
            let payloadString = String(data: payloadData, encoding: .utf8)!

            let hashedPayload = cereal.sha3(string: payloadString)
            let message = "POST\n\(path)\n\(timestamp)\n\(hashedPayload)"
            let signature = "0x\(cereal.sign(message: message))"

            let headers : [String: String] = ["Token-ID-Address": cereal.address, "Token-Signature": signature, "Token-Timestamp": timestamp]
            let json = RequestParameter(parameters)

            self.teapot.post(path, parameters: json, headerFields: headers) { result in
                var status: UserRegisterStatus = .failed

                defer {
                    completion(status)
                }

                switch result {
                case .success(let json, let response):
                    guard response.statusCode == 200 else { return }

                    guard let data = json?.data,
                        let newUser = try? JSONDecoder().decode(Profile.self, from: data)
                        else {
                        assertionFailure("No data from registration request response")
                        return
                    }

                    var user = newUser
                    user.cereal = cereal
                    user.password = UUID().uuidString

                    Profile.current = user

                    status = .registered
                case .failure(_, _, let error):
                    NSLog("\(error)")
                    status = .failed
                }
            }
        }
    }

    public func updateUser(userDictionary: [String: Any], cereal: EtherealCereal, _ success: @escaping (() -> Void)) {
        self.fetchTimestamp { timestamp in
            let path = "/v1/user"

            let payloadData = try! JSONSerialization.data(withJSONObject: userDictionary, options: [])
            let payloadString = String(data: payloadData, encoding: .utf8)!

            let hashedPayload = cereal.sha3(string: payloadString)
            let message = "PUT\n\(path)\n\(timestamp)\n\(hashedPayload)"
            let signature = "0x\(cereal.sign(message: message))"


            let fields: [String: String] = ["Token-ID-Address": cereal.address, "Token-Signature": signature, "Token-Timestamp": String(timestamp)]

            let json = RequestParameter(userDictionary)

            self.teapot.put(path, parameters: json, headerFields: fields) { result in
                switch result {
                case let .success(json, response):
                    guard response.statusCode == 200 else { return }
                    guard let data = json?.data else { return }

                    let updated = try! JSONDecoder().decode(Profile.self, from: data)
                    var user = Profile.current!

                    user.username = updated.username
                    user.name = updated.name
                    user.avatar = updated.avatar

                    Profile.current = user

                    success()
                case let .failure(json, response, error):
                    print(response)
                    print(error)
                    print(json ?? "")
                }
            }
        }
    }

    func findUserWithId(_ id: String, completion: @escaping (_ profile: Profile?) -> Void) {
        self.fetchTimestamp { timestamp in
            self.teapot.get("/v2/user/\(id)", headerFields: ["Token-Timestamp": timestamp]) { (result: NetworkResult) in

                var profile: Profile? = nil

                defer {
                    completion(profile)
                }

                switch result {
                case .success(let json, _):
                    guard let data = json?.data else {
                        fatalError()
                    }

                    let decoder = JSONDecoder()
                    profile = try! decoder.decode(Profile.self, from: data)

                    completion(profile)
                case .failure(_, _, let error):
                    NSLog("%@", error.localizedDescription)
                }
            }
        }
    }
}
