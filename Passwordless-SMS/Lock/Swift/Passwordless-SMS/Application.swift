// Application.swift
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

import Foundation
import Lock

class Application {

    static var sharedInstance = Application()

    var lock = A0Lock()
    var profile: A0UserProfile?
    var token: A0Token?
    var nonSecurePingURL: NSURL
    var securePingURL: NSURL

    private init() {
        let urlString = NSBundle.mainBundle().infoDictionary?["Auth0SampleURL"] as? String ?? "http://localhost:3001"
        let baseURL = NSURL(string: urlString)
        self.nonSecurePingURL = NSURL(string: "/ping", relativeToURL: baseURL)!
        self.securePingURL = NSURL(string: "/secured/ping", relativeToURL: baseURL)!
    }
}
