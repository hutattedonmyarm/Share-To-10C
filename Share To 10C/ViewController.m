//
//  ViewController.m
//  Share To 10C
//
//  Created by Max Nuding on 01.09.15.
//  Copyright © 2015 Max Nuding. All rights reserved.
//

#import "ViewController.h"
@interface ViewController() <NSURLSessionTaskDelegate, NSURLSessionDelegate, NSURLSessionDataDelegate>

@property (weak) IBOutlet NSButton *loginButton;
@property (weak) IBOutlet NSButton *logoutButton;
@property (weak) IBOutlet NSTextField *usernameTextField;
@property (weak) IBOutlet NSSecureTextField *passwordTextField;
@property (weak) IBOutlet NSTextField *statusLabel;

@end
@implementation ViewController

static NSString *groupName = @"group.hutattedonmyarm.posttotenc.app";
static NSString *tenCAuthTokenKey = @"10CAuthToken";
static NSString *currentUserKey = @"currentAuthorizedUser";
static NSString *siteAlphaKey = @"10CsiteAlpha";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Check if we have an auth token, set status label accordingly and en-/disable buttons
    NSUserDefaults *mySharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:groupName];
    if ([mySharedDefaults stringForKey:tenCAuthTokenKey] && [[mySharedDefaults stringForKey:tenCAuthTokenKey ] isNotEqualTo:@""]) {
        [self setUIToAuthorized];
    } else {
        [self setUIToNotAuthorized];
    }
    if ([mySharedDefaults stringForKey:currentUserKey]) {
        self.usernameTextField.stringValue = [mySharedDefaults stringForKey:currentUserKey];
    }
}

-(void)setUIToAuthorized {
    NSUserDefaults *mySharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:groupName];
    self.statusLabel.textColor = [NSColor greenColor];
    self.statusLabel.stringValue = [NSString stringWithFormat:@"Authorized as %@", [mySharedDefaults stringForKey:currentUserKey]];
    self.loginButton.enabled = NO;
    self.logoutButton.enabled = YES;
}

-(void)setUIToNotAuthorized {
    self.statusLabel.textColor = [NSColor redColor];
    self.statusLabel.stringValue = @"Not authorized";
    self.loginButton.enabled = YES;
    self.logoutButton.enabled = NO;
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    //TODO: Add error handling, etc etc
    NSError *jsonerror;
    NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonerror];
    if ([responseDict[@"data"][@"isGood"] isEqualToString:@"Y"]) {
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:groupName];
        [defaults setObject:responseDict[@"data"][@"data"][@"AuthToken"] forKey:tenCAuthTokenKey];
        [defaults setObject:responseDict[@"data"][@"data"][@"SiteAlpha"] forKey:siteAlphaKey];
        [defaults setObject:self.usernameTextField.stringValue forKey:currentUserKey];
        [defaults synchronize];
        [self setUIToAuthorized];
    }
    if (jsonerror) {
        NSLog(@"Error: %@", jsonerror);
    }
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    //We'll let it pass for now. Filter by HTTP Status code later
    completionHandler(NSURLSessionResponseAllow);
}

/*
 Let's do some error handling later on
 
 -(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
 NSLog(@"shit: %@", error);
 }
 -(void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
 NSLog(@"invalid");
 }
 */

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}
- (IBAction)login:(NSButton *)sender {
    NSString *requestbody = [NSString stringWithFormat:@"usrName=%@&usrPass=%@", self.usernameTextField.stringValue, self.passwordTextField.stringValue];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    NSURL *url = [NSURL URLWithString:@"http://admin.10centuries.com/api/a/authenticate"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    request.HTTPBody = [requestbody dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPMethod = @"POST";
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    [task resume];
}

- (IBAction)logout:(NSButton *)sender {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:groupName];
    [defaults setObject:@"" forKey:tenCAuthTokenKey];
    [defaults synchronize];
    [self setUIToNotAuthorized];
}
@end
