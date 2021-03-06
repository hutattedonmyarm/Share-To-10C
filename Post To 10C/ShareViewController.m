//
//  ShareViewController.m
//  Post To 10C
//
//  Created by Max Nuding on 01.09.15.
//  Copyright © 2015 Max Nuding. All rights reserved.
//

#import "ShareViewController.h"

@interface ShareViewController () <NSURLSessionDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate, NSTokenFieldDelegate>
@property (unsafe_unretained) IBOutlet NSTextView *textView;
@property (weak) IBOutlet NSTextField *remainingCharactersLabel;
@property (weak) IBOutlet NSButton *postButton;
@property (weak) IBOutlet NSTextField *authorizedLabel;
@property (weak) IBOutlet NSTextField *postTitleTextField;
@property NSInteger totalLength;
@property (weak) IBOutlet NSTokenField *tagsTokenField;
@property (weak) IBOutlet NSProgressIndicator *uploadProgressBar;
@property uint64_t totalImageSize;
@property uint64_t totalBytesSent;
@property int numberOfImages;
@property int numberOfImagesComplete;

@property BOOL isADNLogin;

#define kADN_PM_LIMIT 2048
#define kTEN_C_APPKEY_KEY @"10CAppKey"
#define kTEN_C_CHAR_LIMIT 10000000
#define kTEN_C_IMG_LIMIT 99000000 //99 bytes * 1000 * 1000 => 99MB. The actual limit is 100MB, but let's be safe. We'Re also using 1000 instead of 1024, I know.

@end

@implementation ShareViewController

static NSString *tenCAuthTokenKey = @"10CAuthToken";
static NSString *currentUserKey = @"currentAuthorizedUser";
static NSString *groupName = @"group.hutattedonmyarm.posttotenc.app";
static NSString *siteAlphaKey = @"10CsiteAlpha";
static NSString *isADNLoginKey = @"isADNLogin";
static NSString *tenCAppKey = @"10CAppKey";
static NSString *tenCTagKey = @"10CTagKey";

static NSString *uploadTaskDescription = @"uploadTask";

- (NSString *)nibName {
    return @"ShareViewController";
}

- (void)loadView {
    [super loadView];
    self.tagsTokenField.delegate = self;
    self.textView.delegate = self;
    self.totalImageSize = 0;
    self.totalBytesSent = 0;
    self.numberOfImages = 0;
    self.numberOfImagesComplete = 0;
    NSExtensionItem *item = self.extensionContext.inputItems.firstObject;
    NSString *t = item.attributedTitle.string;
    if (t) {
        [self.postTitleTextField setStringValue:[self.postTitleTextField.stringValue stringByAppendingString:t]];
    }
    NSString *c = item.attributedContentText.string;
    if (c) {
        [[self.textView textStorage] performSelectorOnMainThread:@selector(appendAttributedString:) withObject:[[NSAttributedString alloc] initWithString:c] waitUntilDone:YES];
    }
    for (NSItemProvider *att in item.attachments) {
        if ([att hasItemConformingToTypeIdentifier:@"public.image"]) {
            [att loadItemForTypeIdentifier:@"public.image" options:kNilOptions completionHandler:^(id item, NSError *error) {
                NSData *imgData = nil;
                if ([item isKindOfClass:[NSImage class]]) {
                    imgData = [item TIFFRepresentation];
                    NSBitmapImageRep *imgRep = [NSBitmapImageRep imageRepWithData:imgData];
                    imgData = [imgRep representationUsingType: NSJPEGFileType properties: @{NSImageCompressionFactor: @1.0}];
                } else {
                    imgData = item;
                }
                [self performSelectorInBackground:@selector(uploadImage:) withObject:imgData];
            }];
        } else if ([att hasItemConformingToTypeIdentifier:@"public.url"]) {
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

-(void)uploadImage:(id)imageData {
    BOOL isPNG = NO;
    uint8_t c;
    [imageData getBytes:&c length:1];
    if (c == 0x89) {
        isPNG = YES;
    }
    NSData *imgData = imageData;
    if (imgData.length > kTEN_C_IMG_LIMIT) {
        [self displayAlertWithTitle:@"Error uploading image" andMessage:@"The image is too big, try a smaller image (<99MB)"];
        NSError *cancelError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
        [self.extensionContext cancelRequestWithError:cancelError];
        return;
    }

    self.numberOfImages++;
    NSBitmapImageRep *imgrep = [NSBitmapImageRep imageRepWithData:imgData];
    if (isPNG) {
        imgData = [imgrep representationUsingType:NSPNGFileType properties:@{NSImageCompressionMethod:@1.0}];
    } else {
        imgData = [imgrep representationUsingType:NSJPEGFileType properties:@{NSImageCompressionMethod:@1.0}];
    }
    NSURL *postURL = [NSURL URLWithString:@"http://admin.10centuries.com/uploads.php"];
    
    NSString *accessKey = [[[NSUserDefaults alloc] initWithSuiteName:groupName] stringForKey:tenCAppKey];
    NSString *authToken = [[[NSUserDefaults alloc] initWithSuiteName:groupName] stringForKey:tenCAuthTokenKey];
    NSString *siteAlpha = [[[NSUserDefaults alloc] initWithSuiteName:groupName] stringForKey:siteAlphaKey];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:postURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    request.HTTPMethod = @"POST";
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    dateFormat.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSString *dateString = [dateFormat stringFromDate:[NSDate date]];
    NSString *filename = @"";
    if (isPNG) {
        filename = [NSString stringWithFormat:@"%@.png", dateString];
    } else {
        filename = [NSString stringWithFormat:@"%@.jpg", dateString];
    }
    
    NSDictionary *params = @{@"accessKey": accessKey, @"token": authToken, @"siteAlpha": siteAlpha, @"location": @"media"};
    NSString* fileParamConstant = @"sendFile";
    NSString *boundaryConstant = @"----------V2ymHFg03ehbqgZCaKO6jy";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundaryConstant];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];
    
    for (NSString *p in [params allKeys]) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", p] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%@\r\n", [params objectForKey:p]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", fileParamConstant, filename] dataUsingEncoding:NSUTF8StringEncoding]];
    if (isPNG) {
        [body appendData:[@"Content-Type: image/png\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    } else {
        [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [body appendData:imgData];
    [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setHTTPBody:body];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    task.taskDescription = uploadTaskDescription;
    [task resume];
    self.totalImageSize += request.HTTPBody.length;
    
}

-(void)hideProgressBar {
    self.uploadProgressBar.hidden = YES;
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
    NSError *jsonerror = nil;
    NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonerror];
    if (jsonerror) {
        [self displayAlertWithTitle:@"Error parsing reponse. Please contact the developer" andMessage:jsonerror.description];
    }
    
    if ([dataTask.taskDescription isEqualToString:uploadTaskDescription]) {
        self.numberOfImagesComplete++;
        if (self.numberOfImagesComplete == self.numberOfImages) {
            [self performSelectorOnMainThread:@selector(hideProgressBar) withObject:nil waitUntilDone:YES];
        }
        if ([responseDict[@"isGood"] isEqualToString:@"Y"]) {
            [[self.textView textStorage] performSelectorOnMainThread:@selector(appendAttributedString:) withObject:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"![image](%@)\n", responseDict[@"cdnurl"]]] waitUntilDone:YES];
        } else {
            [self displayAlertWithTitle:@"Error uploading image" andMessage:@"Do you have enough free space?"];
        }
    } else {
        if ([responseDict[@"data"][@"isGood"] isEqualToString:@"N"]) {
            [self displayAlertWithTitle:@"Error posting" andMessage:responseDict[@"data"][@"Message"]];
        }
    }
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))
    completionHandler {
    completionHandler(NSURLSessionResponseAllow);
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        NSLog(@"shit: %@", error);
    }
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
        NSString *tags = self.tagsTokenField.stringValue;
        
        //Save the new tags for completion
        NSArray *tokenArray = (NSArray *)self.tagsTokenField.objectValue;
        if (tokenArray) {
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            NSMutableSet *newTagsSet = [[NSSet setWithArray:tokenArray] mutableCopy]; //Set to avoid duplicates
            [newTagsSet addObjectsFromArray:[prefs arrayForKey:tenCTagKey]];
            [prefs setObject:[newTagsSet allObjects] forKey:tenCTagKey];
            [prefs synchronize];
        }
        
        NSString *requestbody = [NSString stringWithFormat:@"accessKey=%@&token=%@&title=%@&ptext=%@&ptags=%@&pdate=%@", accessKey, authToken, title, pbody, tags, dateString];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:postURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
        request.HTTPBody = [requestbody dataUsingEncoding:NSUTF8StringEncoding];
        request.HTTPMethod = @"POST";
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
        [task resume];
        
        NSExtensionItem *inputItem = self.extensionContext.inputItems.firstObject;
        NSExtensionItem *outputItem = [inputItem copy];
        outputItem.attributedContentText = [[NSAttributedString alloc] initWithString:self.textView.string];
        NSArray *outputItems = @[outputItem];
        [self.extensionContext completeRequestReturningItems:outputItems completionHandler:nil];
    }
    
}
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.totalBytesSent += bytesSent;
        self.uploadProgressBar.doubleValue = ((double)self.totalBytesSent / self.totalImageSize * 100);
    });
}

- (IBAction)cancel:(id)sender {
    NSError *cancelError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
    [self.extensionContext cancelRequestWithError:cancelError];
}

-(void)displayAlertWithTitle: (NSString *)title andMessage: (NSString *)message {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    alert.informativeText = title;
    alert.messageText = message;
    alert.alertStyle = NSCriticalAlertStyle;
    [alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:YES];
}

-(NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(NSInteger *)selectedIndex {
    NSArray *usedTags = [[NSUserDefaults standardUserDefaults] arrayForKey:tenCTagKey];
    if (!usedTags) {
        return @[]; //No tags used in the past, we can return an empty array
    }
    NSMutableArray *suggestions = [@[] mutableCopy];
    for (NSString *tag in usedTags) {
        if ([tag containsString:substring]) {
            [suggestions addObject:tag];
        }
    }
    return suggestions;
}

@end

