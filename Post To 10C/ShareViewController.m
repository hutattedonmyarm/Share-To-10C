//
//  ShareViewController.m
//  Post To 10C
//
//  Created by Max Nuding on 01.09.15.
//  Copyright © 2015 Max Nuding. All rights reserved.
//

#import "ShareViewController.h"

@interface ShareViewController () <NSURLSessionDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate>
@property (unsafe_unretained) IBOutlet NSTextView *textView;
@property (weak) IBOutlet NSTextField *remainingCharactersLabel;
@property (weak) IBOutlet NSButton *postButton;
@property (weak) IBOutlet NSTextField *authorizedLabel;
@property (weak) IBOutlet NSTextField *postTitleTextField;
@property (weak) IBOutlet NSTextField *tagsTextField;
@property NSInteger totalLength;

@property BOOL isADNLogin;

#define kADN_PM_LIMIT 2048
#define kTEN_C_APPKEY_KEY @"10CAppKey"
#define kTEN_C_CHAR_LIMIT 10000000

@end

@implementation ShareViewController

static NSString *tenCAuthTokenKey = @"10CAuthToken";
static NSString *currentUserKey = @"currentAuthorizedUser";
static NSString *groupName = @"group.hutattedonmyarm.posttotenc.app";
static NSString *siteAlphaKey = @"10CsiteAlpha";
static NSString *isADNLoginKey = @"isADNLogin";
static NSString *tenCAppKey = @"10CAppKey";

- (NSString *)nibName {
    return @"ShareViewController";
}

- (void)loadView {
    //Auth: https://account.app.net/oauth/authenticate?client_id=LzpEruz978ZHrpdRueMeMzDmUd4hEuyK&response_type=token&scope=messages:net.app.core.pm
    [super loadView];
    self.textView.delegate = self;
    // Insert code here to customize the view
    NSExtensionItem *item = self.extensionContext.inputItems.firstObject;
    for (NSItemProvider *att in item.attachments) {
        if ([att hasItemConformingToTypeIdentifier:@"public.url"]) {
            [att loadItemForTypeIdentifier:@"public.url" options:nil completionHandler:^(NSURL *item, NSError *error) {
                NSURL *url = item;
                [self.textView setString:[NSString stringWithFormat:@"[%@](%@)", url.absoluteString, url.absoluteString]];
                //Nasty work around
                [self textDidChange:nil];
            }];
        }
    }
    NSUserDefaults *mySharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:groupName];
    NSString *authToken = [mySharedDefaults stringForKey:tenCAuthTokenKey];
    if (!authToken) {
        self.authorizedLabel.stringValue = @"Not authorized";
        self.authorizedLabel.textColor = [NSColor redColor];
    } else {
        self.authorizedLabel.stringValue = [NSString stringWithFormat:@"Authorized as %@", [mySharedDefaults stringForKey:currentUserKey]];
        self.authorizedLabel.textColor = [NSColor greenColor];
        self.isADNLogin = [mySharedDefaults boolForKey:isADNLoginKey];
    }
}

-(void)textDidChange:(NSNotification *)notification {
    self.totalLength = self.textView.string.length + self.postTitleTextField.stringValue.length;
    NSString *labelText = self.isADNLogin ? [NSString stringWithFormat:@"%lu / %i", self.totalLength, kADN_PM_LIMIT] : @"";
    self.remainingCharactersLabel.stringValue = labelText;
    if ((self.isADNLogin && self.totalLength > kADN_PM_LIMIT) || (!self.isADNLogin && self.totalLength > kTEN_C_CHAR_LIMIT)) {
        self.remainingCharactersLabel.textColor = [NSColor redColor];
        self.postButton.enabled = NO;
    } else {
        self.remainingCharactersLabel.textColor = [NSColor blackColor];
        self.postButton.enabled = YES;
    }
}
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    NSLog(@"data!");
    
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    NSLog(@"download");
}
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    NSLog(@"response: %@", response);
    
}
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeStreamTask:(NSURLSessionStreamTask *)streamTask {
    NSLog(@"stream");
}
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSLog(@"shit: %@", error);
}
- (IBAction)send:(id)sender {
    
    if ((self.isADNLogin && self.totalLength > kADN_PM_LIMIT) || (!self.isADNLogin && self.totalLength > kTEN_C_CHAR_LIMIT)) {
        NSAlert *tooLongAlert = [[NSAlert alloc] init];
        [tooLongAlert addButtonWithTitle:@"OK"];
        tooLongAlert.alertStyle = NSCriticalAlertStyle;
        tooLongAlert.informativeText = @"Post too long";
        unsigned long limit = self.isADNLogin ? kADN_PM_LIMIT : kTEN_C_CHAR_LIMIT;
        tooLongAlert.messageText = [NSString stringWithFormat:@"You are using %lu out of a maximum of %lu characters.", self.totalLength, limit];
    } else {
        
        NSURL *postURL = [NSURL URLWithString:@"http://admin.10centuries.com/api/content/post"];
        NSString *accessKey = [[[NSUserDefaults alloc] initWithSuiteName:groupName] stringForKey:tenCAppKey];
        NSString *authToken = [[[NSUserDefaults alloc] initWithSuiteName:groupName] stringForKey:tenCAuthTokenKey];
        NSString *pbody = self.textView.string;
        NSString *title = self.postTitleTextField.stringValue;
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        dateFormat.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        NSString *dateString = [dateFormat stringFromDate:[NSDate date]];
        NSString *tags = self.tagsTextField.stringValue;
        NSExtensionItem *inputItem = self.extensionContext.inputItems.firstObject;
        NSExtensionItem *outputItem = [inputItem copy];
        outputItem.attributedContentText = [[NSAttributedString alloc] initWithString:self.textView.string];
        NSArray *outputItems = @[outputItem];
        [self.extensionContext completeRequestReturningItems:outputItems completionHandler:nil];
    }
    
}

-(void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    NSLog(@"invalid: %@", error);
}

- (IBAction)cancel:(id)sender {
    NSError *cancelError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
    [self.extensionContext cancelRequestWithError:cancelError];
}

@end

