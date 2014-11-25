//
//  XcodeProjectManipulation.h
//  ContentfulPlugin
//
//  Created by Boris Bügling on 25/11/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DevToolsCore/DevToolsCore.h>

@interface XcodeProjectManipulation : NSObject

-(void)addFileAtPath:(NSString *)filePath toTarget:(id<PBXTarget>)target;
-(NSArray*)targets;
-(NSString*)workspacePath;

@end
