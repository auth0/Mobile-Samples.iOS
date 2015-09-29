// RequestViewController.m
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

#import "RequestViewController.h"
#import <Lock/Lock.h>
#import <CoreGraphics/CoreGraphics.h>
#import "Application.h"

@interface RequestViewController ()

@end

@implementation RequestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    Application *app = [Application sharedInstance];
    self.mailLabel.text = app.profile.nickname;
    self.tokenLabel.text = app.token.idToken;
    self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.height / 2;
    self.profileImageView.layer.masksToBounds = YES;

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:[NSURLRequest requestWithURL:app.profile.picture]
                                            completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    self.profileImageView.image = [[UIImage alloc] initWithData:data];
                                                });
                                            }];
    [task resume];

    self.nonSecureAPIStatus.layer.cornerRadius = self.nonSecureAPIStatus.frame.size.height / 2;
    self.nonSecureAPIStatus.layer.masksToBounds = YES;
    self.secureAPIStatus.layer.cornerRadius = self.secureAPIStatus.frame.size.height / 2;
    self.secureAPIStatus.layer.masksToBounds = YES;
    self.nonSecureAPIStatus.text = @"?";
    self.secureAPIStatus.text = @"?";

    [self.nonSecureActivity startAnimating];
    [self pingWithRequest:[NSURLRequest requestWithURL:app.nonSecurePingURL] callback:^(BOOL success) {
        if (success) {
            self.nonSecureAPIStatus.text = @"✔︎";
            self.nonSecureAPIStatus.backgroundColor = [UIColor greenColor];
            self.statusLabel.text = nil;
        } else {
            self.nonSecureAPIStatus.text = @"✖︎";
            self.nonSecureAPIStatus.backgroundColor = [UIColor redColor];
            self.statusLabel.text = @"Failed request to non secured API.\n Please check app's log";
        }
        [self.nonSecureActivity stopAnimating];
    }];
}

- (IBAction)logout:(id)sender {
    Application *app = [Application sharedInstance];
    app.profile = nil;
    app.token = nil;
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)callAPI:(id)sender {
    Application *app = [Application sharedInstance];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:app.securePingURL];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", app.token.idToken] forHTTPHeaderField:@"Authorization"];
    [self.secureActivity startAnimating];
    self.secureActivity.hidden = NO;
    [self pingWithRequest:request callback:^(BOOL success) {
        if (success) {
            self.secureAPIStatus.text = @"✔︎";
            self.secureAPIStatus.textColor = [UIColor whiteColor];
            self.secureAPIStatus.backgroundColor = [UIColor greenColor];
            self.statusLabel.text = nil;
        } else {
            self.secureAPIStatus.text = @"✖︎";
            self.secureAPIStatus.textColor = [UIColor whiteColor];
            self.secureAPIStatus.backgroundColor = [UIColor redColor];
            self.statusLabel.text = @"Failed request to secured API.\n Please check logs";
        }
        [self.secureActivity stopAnimating];
    }];
}

- (void)pingWithRequest:(NSURLRequest *)request callback:(void(^)(BOOL))callback {
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Failed request with error %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(NO);
            });
            return;
        }
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Received response %@ with status code %@", result, @(httpResponse.statusCode));
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(NSLocationInRange(httpResponse.statusCode, NSMakeRange(200, 100)));
        });
    }];
    [task resume];
}

@end
