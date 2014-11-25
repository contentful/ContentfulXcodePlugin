//
//  XcodeProjectManipulation.m
//  ContentfulPlugin
//
//  Created by Boris Bügling on 25/11/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

#import "XcodeProjectManipulation.h"

@interface XcodeProjectManipulation ()

@property (nonatomic, readonly) id<PBXProject> project;

@end

#pragma mark -

@implementation XcodeProjectManipulation

-(void)addFileAtPath:(NSString *)filePath toTarget:(id<PBXTarget>)target {
    id<PBXFileReference> reference = [self addFileAtPath:filePath];
    [self addFileReference:reference inGroupNamed:@"Resources"];
    [self addFileReference:reference toBuildPhase:@"Sources" target:target];
}

-(id<PBXProject>)project {
    NSString* workspacePath = [self workspacePath];
    for (NSString* file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:workspacePath
                                                                               error:nil]) {
        if ([file.pathExtension isEqualToString:@"xcodeproj"]) {
            NSString* fullPath = [workspacePath stringByAppendingPathComponent:file];
            return [objc_getClass("PBXProject") projectWithFile:fullPath];
        }
    }
    return nil;
}

-(NSArray*)targets {
    return [self.project targets];
}

-(NSString*)workspacePath {
    id workspaceWindowController = [self keyWorkspaceWindowController];
    id workspace = [workspaceWindowController valueForKey:@"_workspace"];

    NSString* path = [[workspace valueForKey:@"representingFilePath"] valueForKey:@"_pathString"];
    return [path stringByDeletingLastPathComponent];
}

- (id)keyWorkspaceWindowController {
    NSArray* workspaceWindowControllers = [objc_getClass("IDEWorkspaceWindowController")
                                           performSelector:@selector(workspaceWindowControllers)];

    for (NSWindowController* controller in workspaceWindowControllers) {
        if ([controller.window isKeyWindow]) {
            return controller;
        }
    }

    return workspaceWindowControllers[0];
}

#pragma mark - Taken from xcproj

- (id<PBXGroup>) groupNamed:(NSString *)groupName inGroup:(id<PBXGroup>)rootGroup parentGroup:(id<PBXGroup> *) parentGroup
{
    for (id<PBXGroup> group in [rootGroup children])
    {
        if ([group isKindOfClass:objc_getClass("PBXGroup")])
        {
            if (parentGroup)
                *parentGroup = rootGroup;

            if ([[group name] isEqualToString:groupName])
            {
                return group;
            }
            else
            {
                id<PBXGroup> subGroup = [self groupNamed:groupName inGroup:group parentGroup:parentGroup];
                if (subGroup)
                    return subGroup;
            }
        }
    }

    if (parentGroup)
        *parentGroup = nil;
    return nil;
}

- (id<PBXGroup>) groupNamed:(NSString *)groupName parentGroup:(id<PBXGroup> *) parentGroup
{
    return [self groupNamed:groupName inGroup:[self.project rootGroup] parentGroup:parentGroup];
}

- (id<PBXFileReference>) addFileAtPath:(NSString *)filePath
{
    if (![filePath hasPrefix:@"/"])
        filePath = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:filePath];

    id<PBXFileReference> fileReference = [self.project fileReferenceForPath:filePath];
    if (!fileReference)
    {
        NSArray *references = [[self.project rootGroup] addFiles:[NSArray arrayWithObject:filePath] copy:NO createGroupsRecursively:NO];
        fileReference = [references lastObject];
    }
    return fileReference;
}

- (BOOL) addFileReference:(id<PBXFileReference>)fileReference inGroupNamed:(NSString *)groupName
{
    id<PBXGroup> group = [self groupNamed:groupName parentGroup:NULL];
    if (!group)
        group = [self.project rootGroup];

    if ([group containsItem:fileReference])
        return YES;

    [group addItem:fileReference];

    return YES;
}

- (BOOL) addFileReference:(id<PBXFileReference>)fileReference
             toBuildPhase:(NSString *)buildPhaseName
                   target:(id<PBXTarget>)target
{
    Class buildPhaseClass = NSClassFromString([NSString stringWithFormat:@"PBX%@BuildPhase", buildPhaseName]);
    id<PBXBuildPhase> buildPhase = [target buildPhaseOfClass:buildPhaseClass];
    if (!buildPhase)
    {
        if ([buildPhaseClass respondsToSelector:@selector(buildPhase)])
        {
            buildPhase = [buildPhaseClass performSelector:@selector(buildPhase)];
            [target addBuildPhase:buildPhase];
        }
    }

    if ([buildPhase containsFileReferenceIdenticalTo:fileReference])
        return YES;
    
    return [buildPhase addReference:fileReference];
}

@end
