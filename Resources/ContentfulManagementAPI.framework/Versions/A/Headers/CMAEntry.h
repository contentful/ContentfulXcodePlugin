//
//  CMAEntry.h
//  Pods
//
//  Created by Boris Bügling on 25/07/14.
//
//

#import <ContentfulManagementAPI/ContentfulManagementAPI.h>

/**
 *  Management extensions for entries.
 */
@interface CMAEntry : CDAEntry <CMAArchiving, CMAPublishing, CMAResource>

/**
 *  Set a new value for the given field. The value will be set for the currently active locale.
 *
 *  @param value The new value for the given field.
 *  @param key   The identifier of the given field.
 */
-(void)setValue:(id)value forFieldWithName:(NSString *)key;

@end
