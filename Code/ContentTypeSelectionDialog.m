//
//  ContentTypeSelectionDialog.m
//  ContentfulPlugin
//
//  Created by Boris Bügling on 10/11/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "ContentTypeSelectionDialog.h"

@interface ContentTypeSelectionDialog ()

@property (weak) IBOutlet NSTextField *accessTokenTextField;
@property (weak) IBOutlet NSButton *generateButton;
@property (weak) IBOutlet NSButton *loginButton;
@property (weak) IBOutlet NSMenu *spaceSelectionMenu;
@property (weak) IBOutlet NSMenu *targetSelectionMenu;

@end

#pragma mark -

@implementation ContentTypeSelectionDialog

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

}

- (IBAction)obtainAccessTokenClicked:(NSButton*)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.contentful.com/developers/documentation/content-management-api/http/#getting-started"]];
}

@end
