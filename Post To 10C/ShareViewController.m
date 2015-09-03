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

@end

@implementation ShareViewController

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
    NSUserDefaults *mySharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: @"group.hutattedonmyarm.posttotenc.app"];
    NSString *authToken = [mySharedDefaults stringForKey:@"authToken"];
    if (!authToken) {
        self.authorizedLabel.stringValue = @"Not authorized";
        self.authorizedLabel.textColor = [NSColor redColor];
    } else {
        self.authorizedLabel.stringValue = @"Authorized";
        self.authorizedLabel.textColor = [NSColor greenColor];
    }
    NSURL *channelURL = [NSURL URLWithString:@"https://api.app.net/channels"];
    [self makeAPIRequestWithURL:channelURL andMethod:@"GET" andHeader:nil andData:nil];
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
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    NSLog(@"response");
}
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSLog(@"shit: %@", error);
}
- (IBAction)send:(id)sender {
    
    //NSDictionary *json = [self makeAPIRequestWithURL:channelURL andMethod:@"GET" andHeader:nil andData:nil];
    //for (NSDictionary *dict in json[@"data"]) {
        //bool newMessage = [((NSNumber *)dict[@"has_unread"]) boolValue] && [@"net.app.core.pm" isEqualToString:dict[@"type"]];
        //if (newMessage) {
        //    [self performSelectorInBackground:@selector(displayNotificationWithIDs:) withObject:@[dict[@"id"], dict[@"recent_message_id"]]];
        //}
        //}
        //NSLog(@"%@", json);
    // Complete implementation by setting the appropriate value on the output item
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

- (NSURLSession *) configureMySession {
    NSURLSession *mySession = nil;
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.hutattedonmyarm.posttotenc.getchannelsession"];
    // To access the shared container you set up, use the sharedContainerIdentifier property on your configuration object.
    config.sharedContainerIdentifier = @"group.hutattedonmyarm.posttotenc.app";
    mySession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    return mySession;
}

-(void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    NSLog(@"invalid: %@", error);
}

- (IBAction)cancel:(id)sender {
    NSError *cancelError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
    [self.extensionContext cancelRequestWithError:cancelError];
}

-(NSDictionary *)makeAPIRequestWithURL:(NSURL *)requestURL andMethod:(NSString *)method andHeader:(NSDictionary *)header andData:(NSData *)data{
    NSDictionary *json = nil;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    NSURLResponse *response = nil;
    NSError *error = nil;
    request.HTTPMethod = method;
    NSUserDefaults *mySharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: @"group.hutattedonmyarm.posttotenc.app"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@",
                       [mySharedDefaults stringForKey:@"authToken"]] forHTTPHeaderField:@"Authorization"];
    for(NSString *key in [header allKeys]) {
        [request setValue:header[key] forHTTPHeaderField:key];
    }
    if (data != nil) {
        request.HTTPBody = data;
    }
    NSURLSession *mySession = [self configureMySession];
    NSURLSessionTask *myTask = [mySession dataTaskWithURL:requestURL];
    [myTask resume];

    /*NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(error != nil) {
        NSLog(@"ADN Error:%@", error);
        
        //We need to dog deeper here than just assume it's an authentication
        NSLog(@"Invalid auth token!");
        return nil;
    } else {
        if (responseData != nil) {
            NSError *jError = nil;
            json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&jError];
        }
    }
    //Checking if our auth token is valid
    if (json != nil && ([json[@"meta"][@"code"] integerValue] == 401 || [json[@"meta"][@"code"] integerValue] == 403)) {
        NSLog(@"Invalid auth token!");
        return nil;
    }*/
    return json;
}

@end

