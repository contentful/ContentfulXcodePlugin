//
//  ContentTypeSelectionDialog.m
//  ContentfulPlugin
//
//  Created by Boris Bügling on 10/11/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <ContentfulManagementAPI/ContentfulManagementAPI.h>
#import <ContentfulManagementAPI/CMAArray.h>
#import <ContentfulManagementAPI/CMAError.h>

#import "BBUSegmentTracker.h"
#import "ContentTypeSelectionDialog.h"
#import "DJProgressHUD.h"
#import "SSKeychain.h"
#import "XcodeProjectManipulation.h"

static NSString* const kContentful      = @"com.contentful.xcode-plugin";
static NSString* const kSegmentToken    = @"yjld8PYNsAZlgJjsFdF96h5FWgm31NBk";

@interface ContentTypeSelectionDialog ()

@property (weak) IBOutlet NSTextField *accessTokenTextField;
@property (strong) CMAClient* client;
@property (weak) IBOutlet NSButton *generateButton;
@property (weak) IBOutlet NSButton *loginButton;
@property (strong) XcodeProjectManipulation* projectManipulation;
@property (strong) CMASpace* selectedSpace;
@property (strong) id<PBXTarget> selectedTarget;
@property (weak) IBOutlet NSButton *spaceSelection;
@property (weak) IBOutlet NSMenu *spaceSelectionMenu;
@property (weak) IBOutlet NSButton *targetSelection;
@property (weak) IBOutlet NSMenu *targetSelectionMenu;
@property (strong) BBUSegmentTracker* tracker;
@property (weak) IBOutlet NSButton *trackingOptOut;

@end

#pragma mark -

@implementation ContentTypeSelectionDialog

// TODO: Move this to CMA SDK so that static builds of it can be shared

// Terrible workaround to keep static builds from stripping these classes out.
+(void)load {
#ifndef __clang_analyzer__
    NSArray* classes = @[ [CMAArray class], [CMAError class], [CMASpace class] ];
    classes = nil;
#endif
}

#pragma mark -

- (void)closeSheet {
    [self.window close];
    [[NSApp keyWindow] endSheet:self.window];
}

- (void)fillMenuWithSpaces:(NSArray*)spaces {
    self.spaceSelection.enabled = spaces.count > 0;

    [self.spaceSelectionMenu removeAllItems];

    spaces = [spaces sortedArrayUsingComparator:^NSComparisonResult(CMASpace* space1, CMASpace* space2) {
        return [space1.name localizedStandardCompare:space2.name];
    }];
    self.selectedSpace = spaces[0];

    [spaces enumerateObjectsUsingBlock:^(CMASpace* space, NSUInteger idx, BOOL *stop) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:space.name
                                                          action:@selector(selectSpace:)
                                                   keyEquivalent:@""];
        menuItem.representedObject = space;
        [self.spaceSelectionMenu addItem:menuItem];
    }];
}

- (void)fillMenuWithTargets:(NSArray*)targets {
    self.targetSelection.enabled = targets.count > 0;

    [self.targetSelectionMenu removeAllItems];

    targets = [targets sortedArrayUsingComparator:^NSComparisonResult(id<PBXTarget> t1, id<PBXTarget> t2) {
        return [[t1 name] localizedStandardCompare:[t2 name]];
    }];
    self.selectedTarget = targets[0];

    [targets enumerateObjectsUsingBlock:^(id<PBXTarget> target, NSUInteger idx, BOOL *stop) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:target.name
                                                          action:@selector(selectTarget:)
                                                   keyEquivalent:@""];
        menuItem.representedObject = target;
        [self.targetSelectionMenu addItem:menuItem];
    }];
}

- (instancetype)init {
    self = [super initWithWindowNibName:NSStringFromClass(self.class)];
    if (self) {
        self.projectManipulation = [XcodeProjectManipulation new];
        self.tracker = [[BBUSegmentTracker alloc] initWithToken:kSegmentToken];
    }
    return self;
}

-(void)performLogin {
    CDAConfiguration* configuration = [CDAConfiguration defaultConfiguration];
    configuration.userAgent = @"Contentful Xcode Plugin/0.3";

    self.client = [[CMAClient alloc] initWithAccessToken:self.accessTokenTextField.stringValue
                                           configuration:configuration];

    [self.client fetchAllSpacesWithSuccess:^(CDAResponse *response, CDAArray *array) {
        [SSKeychain setPassword:self.accessTokenTextField.stringValue
                     forService:kContentful
                        account:kContentful];

        [self fillMenuWithSpaces:array.items];
        [self fillMenuWithTargets:[self.projectManipulation targets]];

        self.generateButton.enabled = self.spaceSelection.enabled && self.targetSelection.enabled;
    } failure:^(CDAResponse *response, NSError *error) {
        NSAlert* alert = [NSAlert alertWithError:error];
        [alert runModal];
    }];
}

-(void)selectSpace:(NSMenuItem*)menuItem {
    self.selectedSpace = menuItem.representedObject;
}

-(void)selectTarget:(NSMenuItem*)menuItem {
    self.selectedTarget = menuItem.representedObject;
}

-(void)windowDidLoad {
    [super windowDidLoad];

    self.accessTokenTextField.stringValue = [SSKeychain passwordForService:kContentful
                                                                   account:kContentful] ?: @"";
    [self performLogin];
}

#pragma mark - Actions

- (IBAction)cancelButtonClicked:(NSButton *)sender {
    [self closeSheet];
}

- (IBAction)generateClicked:(NSButton *)sender {
    if (self.trackingOptOut.state == NSOnState) {
        [self.tracker trackEvent:NSStringFromSelector(_cmd) withProperties:@{} completionHandler:nil];
    }

    NSString* generatorBinaryPath = [[NSBundle bundleForClass:self.class] pathForResource:@"ContentfulModelGenerator" ofType:nil];

    NSTask* task = [NSTask new];
    task.arguments = @[@"generate", [@"--spaceKey=" stringByAppendingString:self.selectedSpace.identifier], [@"--accessToken=" stringByAppendingString:self.accessTokenTextField.stringValue]];
    task.currentDirectoryPath = [self.projectManipulation workspacePath];
    task.launchPath = generatorBinaryPath;

    NSPipe* errorPipe = [NSPipe pipe];
    task.standardError = errorPipe;

    [DJProgressHUD showStatus:NSLocalizedString(@"Generating...", nil)
                     FromView:self.window.contentView];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [task launch];
        [task waitUntilExit];

        dispatch_sync(dispatch_get_main_queue(), ^{
            [DJProgressHUD dismiss];
        });

        NSString* potentialPath = [[self.projectManipulation workspacePath] stringByAppendingPathComponent:@"ContentfulModel.xcdatamodeld"];
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:potentialPath];

        dispatch_sync(dispatch_get_main_queue(), ^{
            if (!exists) {
                NSString* errorString = [[NSString alloc] initWithData:[[errorPipe fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding];

                NSAlert* alert = [NSAlert new];
                alert.messageText = [NSString stringWithFormat:NSLocalizedString(@"Could not generate data model: %@", nil), errorString];
                [alert runModal];
            } else {
                [self.projectManipulation addFileAtPath:potentialPath toTarget:self.selectedTarget];
            }
            
            [self closeSheet];
        });
    });
}

- (IBAction)loginClicked:(NSButton*)sender {
    [self performLogin];
}

- (IBAction)obtainAccessTokenClicked:(NSButton*)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.contentful.com/developers/documentation/content-management-api/http/#getting-started"]];
}

@end
