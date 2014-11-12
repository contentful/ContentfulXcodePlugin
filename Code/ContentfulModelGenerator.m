//
//  ContentfulModelGenerator.m
//  ContentfulPlugin
//
//  Created by Boris Bügling on 10/11/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <ContentfulDeliveryAPI/ContentfulDeliveryAPI.h>

#import "ContentfulModelGenerator.h"

@interface ContentfulModelGenerator ()

@property (nonatomic) CDAClient* client;

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

-(instancetype)initWithClient:(CDAClient*)client {
    self = [super init];
    if (self) {
        self.client = client;
    }
    return self;
}

-(NSEntityDescription*)generateEntityForContentType:(CDAContentType*)contentType {
    NSEntityDescription* entity = [[self class] entityWithName:contentType.name];

    for (CDAField* field in contentType.fields) {
        if (field.disabled) {
            continue;
        }

        switch (field.type) {
            case CDAFieldTypeLink:
                break;
            case CDAFieldTypeNone:
                continue;
            default: {
                break;
            }
        }
    }

    return entity;
}

-(void)generateModelForContentTypesWithCompletionHandler:(CDAModelGenerationHandler)handler {
    NSParameterAssert(handler);

    [self.client fetchContentTypesWithSuccess:^(CDAResponse *response, CDAArray *array) {
        NSMutableArray* entities = [@[] mutableCopy];

        for (CDAContentType* contentType in array.items) {
            NSEntityDescription* entity = [self generateEntityForContentType:contentType];
            [entities addObject:entity];
        }

        NSManagedObjectModel* model = [NSManagedObjectModel new];
        model.entities = [entities copy];
        handler(model, nil);
    } failure:^(CDAResponse *response, NSError *error) {
        handler(nil, error);
    }];
}

@end
