//
//  ContentfulPlugin.m
//  ContentfulPlugin
//
//  Created by Boris Bügling on 10/11/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import "ContentfulPlugin.h"
#import "ContentTypeSelectionDialog.h"

static ContentfulPlugin *sharedPlugin;

@interface ContentfulPlugin()

@property (nonatomic, strong, readwrite) NSBundle *bundle;
@property (nonatomic, strong, readwrite) ContentTypeSelectionDialog* contentTypeSelectionDialog;

@end

#pragma mark -

@implementation ContentfulPlugin

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }
}

+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

#pragma mark -

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        self.bundle = plugin;

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self createMenuItem];
        }];
    }
    return self;
}

- (void)createMenuItem {
    NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Product"];
    if (menuItem) {
        [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
        NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Generate Model from Contentful..." action:@selector(doMenuAction) keyEquivalent:@""];
        [actionMenuItem setTarget:self];
        [[menuItem submenu] addItem:actionMenuItem];
    }
}

- (void)doMenuAction
{
    self.contentTypeSelectionDialog = [ContentTypeSelectionDialog new];
    [[NSApp keyWindow] beginSheet:self.contentTypeSelectionDialog.window completionHandler:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    return [NSStringFromClass([NSApp keyWindow].class) isEqualToString:@"IDEWorkspaceWindow"];
}

@end
