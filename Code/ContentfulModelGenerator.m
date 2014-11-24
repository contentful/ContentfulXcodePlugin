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

@property (nonatomic) NSEntityDescription* assetEntity;
@property (nonatomic) CMAClient* client;
@property (nonatomic) NSDictionary* contentTypes;
@property (nonatomic) NSMutableDictionary* entities;
@property (nonatomic) NSMutableArray* relationshipsForPostProcessing;
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

-(CDAContentType*)contentTypeValidationForField:(CMAField*)field {
    if (field.itemType != CDAFieldTypeEntry) {
        return nil;
    }

    NSArray* validations = [field.validations valueForKey:@"dictionaryRepresentation"];

    for (NSDictionary* validation in validations) {
        NSArray* possibleValidation = validation[@"linkContentType"];

        if ([possibleValidation isKindOfClass:NSString.class]) {
            return self.contentTypes[possibleValidation];
        }

        if (possibleValidation.count == 1) {
            return self.contentTypes[possibleValidation[0]];
        }
    }

    return nil;
}

-(instancetype)initWithClient:(CMAClient *)client spaceKey:(NSString *)spaceKey {
    self = [super init];
    if (self) {
        self.client = client;
        self.entities = [@{} mutableCopy];
        self.relationshipsForPostProcessing = [@[] mutableCopy];
        self.spaceKey = spaceKey;
    }
    return self;
}

-(NSEntityDescription*)generateEntityForContentType:(CDAContentType*)contentType {
    NSEntityDescription* entity = [[self class] entityWithName:contentType.name];
    self.entities[contentType.identifier] = entity;
    return entity;
}

-(void)handleFieldsForContentType:(CDAContentType*)contentType {
    NSEntityDescription* entity = self.entities[contentType.identifier];

    NSMutableArray* properties = [@[] mutableCopy];

    for (CMAField* field in contentType.fields) {
        if (field.disabled) {
            continue;
        }

        switch (field.type) {
            case CDAFieldTypeArray:
            case CDAFieldTypeLink: {
                if (field.itemType != CDAFieldTypeAsset && field.itemType != CDAFieldTypeEntry) {
                    continue;
                }

                NSRelationshipDescription* relation = [NSRelationshipDescription new];
                relation.name = field.identifier;
                relation.maxCount = field.type == CDAFieldTypeArray ? 0 : 1;
                relation.ordered = field.type == CDAFieldTypeArray;
                relation.optional = YES;

                if (field.itemType == CDAFieldTypeAsset) {
                    relation.destinationEntity = self.assetEntity;
                } else {
                    CDAContentType* contentType = [self contentTypeValidationForField:field];

                    if (!contentType) {
                        fprintf(stderr, "%s\n", [[NSString stringWithFormat:@"Error: field '%@' (content-type %@) is missing content type validations.", field.identifier, contentType.identifier] cStringUsingEncoding:NSUTF8StringEncoding]);
                        exit(1);
                    }

                    relation.destinationEntity = self.entities[contentType.identifier];
                }

                [properties addObject:relation];
                [self.relationshipsForPostProcessing addObject:relation];
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

            NSMutableDictionary* contentTypes = [@{} mutableCopy];
            for (CDAContentType* contentType in array.items) {
                contentTypes[contentType.identifier] = contentType;
            }
            self.contentTypes = contentTypes;

            self.assetEntity = [self generateStandardEntityForAssets];
            [entities addObject:self.assetEntity];
            [entities addObject:[self generateStandardEntityForSyncInfo]];

            for (CDAContentType* contentType in self.contentTypes.allValues) {
                NSEntityDescription* entity = [self generateEntityForContentType:contentType];
                [entities addObject:entity];
            }

            for (CDAContentType* contentType in self.contentTypes.allValues) {
                [self handleFieldsForContentType:contentType];
            }

            for (NSEntityDescription* entity in entities) {
                for (NSRelationshipDescription* relation in entity.relationshipsByName.allValues) {
                    relation.inverseRelationship = [self relationshipWithTarget:entity];
                }
            }

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

-(NSRelationshipDescription*)relationshipWithTarget:(NSEntityDescription*)entity {
    for (NSRelationshipDescription* relation in self.relationshipsForPostProcessing) {
        if (relation.destinationEntity == entity) {
            return relation;
        }
    }

    return nil;
}

@end
