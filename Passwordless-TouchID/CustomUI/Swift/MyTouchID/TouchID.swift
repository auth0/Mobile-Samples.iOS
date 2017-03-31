// TouchID.swift
//
// Copyright (c) 2015 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import Lock
import SimpleKeychain
import TouchIDAuth

enum Result {
    case Success(A0UserProfile, A0Token)
    case Error(NSError)
}
struct TouchID {

    let authentication: A0TouchIDAuthentication

    init(client: A0APIClient, userClient: A0UserAPIClient, userId: String, callback: @escaping (Result) -> Void) {
        let device = UIDevice.current.identifierForVendor!.uuidString
        self.init(client: client, userId: userId, registerBlock: { (pubKey, completed, errored) in
            let registerBlock = {
                userClient.registerPublicKey(pubKey,
                    device: device,
                    user: userId,
                    success: { completed() },
                    failure: { error in errored(error) })
            }

            userClient.removePublicKey(ofDevice: device,
                user:userId,
                success: { registerBlock() },
                failure: { _ in registerBlock() })
            }, callback: callback)
    }

    init(client: A0APIClient, userId: String, callback: @escaping (Result) -> Void) {
        self.init(client: client, userId: userId, registerBlock: { (_, completed, _) in completed() }, callback: callback)
    }

    init(client: A0APIClient, userId: String, registerBlock: @escaping (Data, @escaping A0RegisterCompletionBlock,@escaping A0ErrorBlock) -> Void, callback: @escaping (Result) -> Void) {
        let device = UIDevice.current.identifierForVendor!.uuidString

        let authentication = A0TouchIDAuthentication()
        authentication.registerPublicKey = registerBlock

        authentication.jwtPayload = {
            return [
                "iss": userId,
                "device": device,
            ]
        }

        authentication.authenticate = { (jwt, block) in
            let parameters = A0AuthParameters.new(with: [
                A0ScopeProfile: "openid name email nickname"
                ])

            client.login(withIdToken: jwt,
                deviceName: device,
                parameters: parameters,
                success: { (profile, token) in
                    callback(.Success(profile, token))
                },
                failure: { (error) in block(error) })
        }
        authentication.onError = { error in
            callback(.Error(error as NSError))
        }

        self.authentication = authentication
    }

    func authenticate() {
        self.authentication.start()
    }

    func reset() {
        self.authentication.reset()
    }
}
