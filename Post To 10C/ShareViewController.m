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

#define kADN_PM_LIMIT 2048
#define kTEN_C_APPKEY_KEY @"10CAppKey"

@end

@implementation ShareViewController

static NSString *tenCAuthTokenKey = @"10CAuthToken";
static NSString *currentUserKey = @"currentAuthorizedUser";
static NSString *groupName = @"group.hutattedonmyarm.posttotenc.app";
static NSString *siteAlphaKey = @"10CsiteAlpha";

- (NSString *)nibName {
    return @"ShareViewController";
}

/***************************************************************************************
 * Warning: Big mess currently due to various attempts at playing with networking code *
 ***************************************************************************************/

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
    }
}

-(void)textDidChange:(NSNotification *)notification {
    [self.remainingCharactersLabel setStringValue:[NSString stringWithFormat:@"%lu / %i", self.textView.string.length, kADN_PM_LIMIT]];
    if (self.textView.string.length > kADN_PM_LIMIT) {
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
    
    if (self.textView.string.length > kADN_PM_LIMIT) {
        NSLog(@"Too long");
    } else {
        NSLog(@"Sending: %@", self.textView.string);
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

