//
//  AppDelegate.m
//  Share To 10C
//
//  Created by Max Nuding on 01.09.15.
//  Copyright © 2015 Max Nuding. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate () <NSURLSessionTaskDelegate, NSURLSessionDelegate, NSURLSessionDataDelegate>



@end

@implementation AppDelegate

static NSString *groupName = @"group.hutattedonmyarm.posttotenc.app";
static NSString *tenCAuthTokenKey = @"10CAuthToken";

-(void)applicationWillFinishLaunching:(NSNotification *)notification {
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleAppleEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

//Handle auth via ADN
- (void)handleAppleEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSString *token = [urlString componentsSeparatedByString:@"access_token="][1];
    NSUserDefaults *mySharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: groupName];
    [mySharedDefaults setObject:token forKey:@"authToken"];
    [mySharedDefaults synchronize];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
