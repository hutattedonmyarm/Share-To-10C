//
//  ShareViewController.m
//  Post To 10C
//
//  Created by Max Nuding on 01.09.15.
//  Copyright © 2015 Max Nuding. All rights reserved.
//

#import "ShareViewController.h"

@interface ShareViewController ()
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

- (IBAction)send:(id)sender {
    
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

- (IBAction)cancel:(id)sender {
    NSError *cancelError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
    [self.extensionContext cancelRequestWithError:cancelError];
}

@end

