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

@end

@implementation ShareViewController

- (NSString *)nibName {
    return @"ShareViewController";
}

- (void)loadView {
    [super loadView];
    
    // Insert code here to customize the view
    NSArray *inputItems = self.extensionContext.inputItems;
    
    for (NSExtensionItem *item in inputItems) {
        for (NSItemProvider *att in item.attachments) {
            if ([att hasItemConformingToTypeIdentifier:@"public.url"]) {
                [att loadItemForTypeIdentifier:@"public.url" options:nil completionHandler:^(NSURL *item, NSError *error) {
                    NSURL *url = item;
                    [self.textView setString:[NSString stringWithFormat:@"[%@](%@)", url.absoluteString, url.absoluteString]];
                }];
            }
        }
    }
}

- (IBAction)send:(id)sender {
    NSExtensionItem *outputItem = [[NSExtensionItem alloc] init];
    // Complete implementation by setting the appropriate value on the output item
    if (self.textView.string.length > 2048) {
        NSLog(@"Too long");
    } else {
       NSLog(@"Sending: %@", self.textView.string);
        outputItem.attachments = @[[[NSItemProvider alloc] initWithItem: @{NSExtensionItemAttributedContentTextKey: @{@"post":self.textView.string}} typeIdentifier:(NSString *)kUTTypeText]];
        NSArray *outputItems = @[outputItem];
        [self.extensionContext completeRequestReturningItems:outputItems completionHandler:nil];
    }
    
}

- (IBAction)cancel:(id)sender {
    NSError *cancelError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
    [self.extensionContext cancelRequestWithError:cancelError];
}

@end

