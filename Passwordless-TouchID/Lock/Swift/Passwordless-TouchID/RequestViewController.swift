// RequestViewController.swift
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

class RequestViewController: UIViewController {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var tokenLabel: UILabel!
    @IBOutlet weak var nonSecureActivity: UIActivityIndicatorView!
    @IBOutlet weak var secureActivity: UIActivityIndicatorView!
    @IBOutlet weak var nonSecureStatus: UILabel!
    @IBOutlet weak var secureStatus: UILabel!
    @IBOutlet weak var message: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        let app = Application.sharedInstance
        self.emailLabel.text = app.profile?.email
        self.tokenLabel.text = app.token?.idToken

        let session = URLSession.shared
        if let pictureURL = app.profile?.picture {
            let task = session.dataTask(with: pictureURL, completionHandler: { [weak self] (data, _, error) -> Void in
                DispatchQueue.main.async {
                    if let imageData = data {
                        self?.profileImageView.image = UIImage(data: imageData)
                    }
                }
            })
            task.resume()
        }
        self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.height / 2
        self.profileImageView.layer.masksToBounds = true

        self.nonSecureStatus.layer.cornerRadius = self.nonSecureStatus.frame.size.height / 2
        self.nonSecureStatus.layer.masksToBounds = true
        self.secureStatus.layer.cornerRadius = self.secureStatus.frame.size.height / 2
        self.secureStatus.layer.masksToBounds = true
        self.nonSecureActivity.startAnimating()
        self.performRequest(request: NSURLRequest(url: app.nonSecurePingURL as URL)) { [weak self] success in
            self?.nonSecureStatus.text = success ? "✔︎" : "✖︎"
            self?.nonSecureStatus.backgroundColor = success ? UIColor.green : UIColor.red
            self?.message.text = success ? nil : "Failed request to non secured API.\n Please check app's log"
            self?.nonSecureActivity.stopAnimating()
        }
    }

    @IBAction func logout(sender: AnyObject) {
        let app = Application.sharedInstance
        app.token = nil
        app.profile = nil
        self.navigationController?.popToRootViewController(animated: true)
    }

    @IBAction func callAPI(sender: AnyObject) {
        let app = Application.sharedInstance
        let request = NSMutableURLRequest(url: app.securePingURL as URL)
        let token = app.token!.idToken
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        self.secureActivity.startAnimating()
        self.secureActivity.isHidden = false
        self.performRequest(request: request) { [weak self] success in
            self?.secureStatus.text = success ? "✔︎" : "✖︎"
            self?.secureStatus.backgroundColor = success ? UIColor.green : UIColor.red
            self?.message.text = success ? nil : "Failed request to secured API.\n Please check app's log"
            self?.secureActivity.stopAnimating()
        }
    }

    private func performRequest(request: NSURLRequest, callback: @escaping (Bool) -> ()) {
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            switch(data, response as? HTTPURLResponse, error) {
            case (_, _, let .some(error)):
                print("Failed request with error \(error)")
                DispatchQueue.main.async(execute: { callback(false) })
            case (let .some(data), let .some(response), nil):
                let result = String(data: data, encoding: String.Encoding.utf8)
                print("Received response \(result) with status code \(response.statusCode)")
                DispatchQueue.main.async { callback(200..<300 ~= response.statusCode) }
            default:
                print("Failed request with unkown error")
                DispatchQueue.main.async { callback(false) }
            }
        }
        task.resume()
    }
}
