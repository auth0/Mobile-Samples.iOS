// LoginViewController.swift
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

class LoginViewController: UIViewController {

    @IBOutlet weak var instagramButton: UIButton!
    @IBOutlet weak var touchIDButton: UIButton!

    var touchID: TouchID!
    var userId: String?

    enum Key : String {
        case UserId = "com.auth0.mytouchid.user"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let defaults = NSUserDefaults.standardUserDefaults()
        self.userId = defaults.stringForKey(Key.UserId.rawValue)
        self.touchIDButton.enabled = self.userId != nil
    }

    @IBAction func loginWithInstagram(sender: AnyObject) {
        self.loginWithConnectionName("instagram")
    }
    
    @IBAction func loginWithTouchID(sender: AnyObject) {
        let lock = MyApplication.sharedInstance.lock
        if let userId = self.userId {
            self.touchID = TouchID(client: lock.apiClient(), userId: userId) { result -> () in
                switch(result) {
                case .Success(let profile, let token):
                    self.showAlertWithTitle("Authenticated with Touch ID", message: "Authenticated user \(profile.nickname)")
                    print("Authenticated user \(profile.name) id_token \(token.idToken)")
                case .Error(let error):
                    self.showAlertWithTitle("Failed to authenticate", message: "Failed to authenticate with Touch ID with error \(error.localizedDescription)");
                    print("Failed to enroll Touch ID with error \(error)")
                }
            }
            self.touchID.authenticate()
        }
    }

    private func loginWithConnectionName(connection: String) {
        let lock = MyApplication.sharedInstance.lock

        lock.identityProviderAuthenticator().authenticateWithConnectionName(connection, parameters: nil,
            success: {[weak self] (profile, token) -> () in
                let userClient = lock.newUserAPIClientWithIdToken(token.idToken)
                self?.touchID = TouchID(client: lock.apiClient(), userClient: userClient, userId: profile.userId) { result -> () in
                    switch(result) {
                    case .Success(let profile, let token):
                        let defaults = NSUserDefaults.standardUserDefaults()
                        defaults.setObject(profile.userId, forKey: Key.UserId.rawValue)
                        defaults.synchronize()
                        self?.showAlertWithTitle("Authenticated with Touch ID", message: "Authenticated user \(profile.nickname)")
                        print("Authenticated user \(profile.name) id_token \(token.idToken)")
                    case .Error(let error):
                        self?.showAlertWithTitle("Failed to authenticate", message: "Failed to authenticate with Touch ID with error \(error.localizedDescription)");
                        print("Failed to authenticate with Touch ID with error \(error)")
                    }
                }
                self?.touchID.reset()
                self?.touchID.authenticate()
            },
            failure: { (error) -> () in
                print("Failed with error \(error)")
        })
    }

    private func showAlertWithTitle(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        self.presentViewController(alertController, animated: true) {}
    }
}
