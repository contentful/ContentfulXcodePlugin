//
//  ContentfulModelGenerator.h
//  ContentfulPlugin
//
//  Created by Boris Bügling on 10/11/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@class CDAClient;

typedef void(^CDAModelGenerationHandler)(NSManagedObjectModel* model, NSError* error);

@interface ContentfulModelGenerator : NSObject

-(void)generateModelForContentTypesWithCompletionHandler:(CDAModelGenerationHandler)handler;
-(instancetype)initWithClient:(CDAClient*)client;

@end
