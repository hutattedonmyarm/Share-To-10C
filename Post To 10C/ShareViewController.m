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

@end

@implementation ShareViewController

- (NSString *)nibName {
    return @"ShareViewController";
}
- (void)loadView {
    [super loadView];
    self.textView.delegate = self;
    // Insert code here to customize the view
    NSArray *inputItems = self.extensionContext.inputItems;
    
    for (NSExtensionItem *item in inputItems) {
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
    }
}

-(void)textDidChange:(NSNotification *)notification {
    [self.remainingCharactersLabel setStringValue:[NSString stringWithFormat:@"%lu / 2048", self.textView.string.length]];
    NSLog(@"CHANGE");
}

- (IBAction)send:(id)sender {
    
    // Complete implementation by setting the appropriate value on the output item
    if (self.textView.string.length > 2048) {
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

