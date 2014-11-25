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

#import "ContentTypeSelectionDialog.h"

@interface ContentTypeSelectionDialog ()

@property (weak) IBOutlet NSTextField *accessTokenTextField;
@property (strong) CMAClient* client;
@property (weak) IBOutlet NSButton *generateButton;
@property (weak) IBOutlet NSButton *loginButton;
@property (weak) IBOutlet NSMenu *spaceSelectionMenu;
@property (weak) IBOutlet NSMenu *targetSelectionMenu;

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

- (instancetype)init {
    self = [super initWithWindowNibName:NSStringFromClass(self.class)];
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

#pragma mark - Actions

- (IBAction)cancelButtonClicked:(NSButton *)sender {
    [self closeSheet];
}

- (IBAction)generateClicked:(NSButton *)sender {

}

- (IBAction)loginClicked:(NSButton*)sender {
    self.client = [[CMAClient alloc] initWithAccessToken:self.accessTokenTextField.stringValue];

    [self.client fetchAllSpacesWithSuccess:^(CDAResponse *response, CDAArray *array) {
        NSLog(@"%@", array);
    } failure:^(CDAResponse *response, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (IBAction)obtainAccessTokenClicked:(NSButton*)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.contentful.com/developers/documentation/content-management-api/http/#getting-started"]];
}

@end
