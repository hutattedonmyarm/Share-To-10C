//
//  AppDelegate.m
//  Share To 10C
//
//  Created by Max Nuding on 01.09.15.
//  Copyright © 2015 Max Nuding. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

-(void)applicationWillFinishLaunching:(NSNotification *)notification {
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleAppleEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSUserDefaults *mySharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: @"group.hutattedonmyarm.posttotenc.app"];
    NSString *authToken = [mySharedDefaults stringForKey:@"authToken"];
    if (!authToken) {
        NSLog(@"auth...");
        [[NSWorkspace sharedWorkspace] openURL:
         [NSURL URLWithString:@"https://account.app.net/oauth/authenticate?client_id=LzpEruz978ZHrpdRueMeMzDmUd4hEuyK&response_type=token&redirect_uri=sharetotenc://&scope=messages:net.app.core.pm"]];
    } else {
        NSLog(@"already authed");
    }
}

- (void)handleAppleEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSString *token = [urlString componentsSeparatedByString:@"access_token="][1];
    NSUserDefaults *mySharedDefaults = [[NSUserDefaults alloc] initWithSuiteName: @"group.hutattedonmyarm.posttotenc.app"];
    [mySharedDefaults setObject:token forKey:@"authToken"];
    [mySharedDefaults synchronize];
    NSLog(@"sucess");
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
