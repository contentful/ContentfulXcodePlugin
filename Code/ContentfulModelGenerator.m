//
//  ContentfulModelGenerator.m
//  ContentfulPlugin
//
//  Created by Boris Bügling on 10/11/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <ContentfulManagementAPI/ContentfulManagementAPI.h>

#import "ContentfulModelGenerator.h"

@interface ContentfulModelGenerator ()

@property (nonatomic) CMAClient* client;
@property (nonatomic) NSString* spaceKey;

@end

#pragma mark -

@implementation ContentfulModelGenerator

+ (NSAttributeType)attributeTypeFromFieldType:(CDAFieldType)fieldType {
    switch (fieldType) {
        case CDAFieldTypeBoolean:
            return NSBooleanAttributeType;
        case CDAFieldTypeDate:
            return NSDateAttributeType;
        case CDAFieldTypeInteger:
            return NSInteger64AttributeType;
        case CDAFieldTypeLocation:
        case CDAFieldTypeObject:
            return NSTransformableAttributeType;
        case CDAFieldTypeNumber:
            return NSDoubleAttributeType;
        case CDAFieldTypeSymbol:
        case CDAFieldTypeText:
            return NSStringAttributeType;
        default:
            break;
    }

    return NSUndefinedAttributeType;
}

+ (NSAttributeDescription*)attributeWithName:(NSString*)name type:(NSAttributeType)type {
    NSAttributeDescription* veryAttribute = [NSAttributeDescription new];
    veryAttribute.name = name;
    veryAttribute.attributeType = type;
    return veryAttribute;
}

+ (NSEntityDescription*)entityWithName:(NSString*)name {
    NSEntityDescription* suchEntity = [NSEntityDescription new];
    suchEntity.name = name;
    suchEntity.managedObjectClassName = suchEntity.name;
    return suchEntity;
}

#pragma mark -

-(instancetype)initWithClient:(CMAClient *)client spaceKey:(NSString *)spaceKey {
    self = [super init];
    if (self) {
        self.client = client;
        self.spaceKey = spaceKey;
    }
    return self;
}

-(NSEntityDescription*)generateEntityForContentType:(CDAContentType*)contentType {
    NSEntityDescription* entity = [[self class] entityWithName:contentType.name];

    NSMutableArray* properties = [@[] mutableCopy];

    for (CDAField* field in contentType.fields) {
        if (field.disabled) {
            continue;
        }

        switch (field.type) {
            case CDAFieldTypeArray:
            case CDAFieldTypeLink: {
                NSRelationshipDescription* relation = [NSRelationshipDescription new];
                relation.name = field.identifier;
                relation.optional = YES;
                //relation.destinationEntity = nil;

                [properties addObject:relation];
                break;
            }
            case CDAFieldTypeNone:
                continue;
            default: {
                NSAttributeDescription* attribute = [[self class] attributeWithName:field.identifier type:[[self class] attributeTypeFromFieldType:field.type]];

                [properties addObject:attribute];
                break;
            }
        }
    }

    [properties addObject:[[self class] attributeWithName:@"identifier" type:NSStringAttributeType]];
    
    entity.properties = properties;
    return entity;
}

-(NSEntityDescription*)generateStandardEntityForAssets {
    NSEntityDescription* entity = [[self class] entityWithName:@"Asset"];

    NSMutableArray* properties = [@[] mutableCopy];

    NSAttributeDescription* attribute = [[self class] attributeWithName:@"height" type:NSFloatAttributeType];
    [properties addObject:attribute];

    attribute = [[self class] attributeWithName:@"width" type:NSFloatAttributeType];
    [properties addObject:attribute];

    for (NSString* attributeName in @[ @"identifier", @"internetMediaType", @"url" ]) {
        attribute = [[self class] attributeWithName:attributeName type:NSStringAttributeType];
        [properties addObject:attribute];
    }

    entity.properties = properties;
    return entity;
}

-(NSEntityDescription*)generateStandardEntityForSyncInfo {
    NSEntityDescription* entity = [[self class] entityWithName:@"SyncInfo"];

    NSMutableArray* properties = [@[] mutableCopy];

    NSAttributeDescription* attribute = [[self class] attributeWithName:@"lastSyncTimestamp"
                                                                   type:NSDateAttributeType];
    [properties addObject:attribute];

    attribute = [[self class] attributeWithName:@"syncToken" type:NSStringAttributeType];
    [properties addObject:attribute];

    entity.properties = properties;
    return entity;
}

-(void)generateModelForContentTypesWithCompletionHandler:(CDAModelGenerationHandler)handler {
    NSParameterAssert(handler);

    [self.client fetchSpaceWithIdentifier:self.spaceKey success:^(CDAResponse *response, CMASpace *space) {
        [space fetchContentTypesWithSuccess:^(CDAResponse *response, CDAArray *array) {
            NSMutableArray* entities = [@[] mutableCopy];

            for (CDAContentType* contentType in array.items) {
                NSEntityDescription* entity = [self generateEntityForContentType:contentType];
                [entities addObject:entity];
            }

            [entities addObject:[self generateStandardEntityForAssets]];
            [entities addObject:[self generateStandardEntityForSyncInfo]];

            NSManagedObjectModel* model = [NSManagedObjectModel new];
            model.entities = [entities copy];
            handler(model, nil);
        } failure:^(CDAResponse *response, NSError *error) {
            handler(nil, error);
        }];
    } failure:^(CDAResponse *response, NSError *error) {
        handler(nil, error);
    }];
}

@end
