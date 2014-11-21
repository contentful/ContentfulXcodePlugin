//
//  CMAUser.h
//  Pods
//
//  Created by Boris Bügling on 15/09/14.
//
//

#import <ContentfulManagementAPI/ContentfulManagementAPI.h>

/**
 *  Represents metadata of a Contentful user account.
 */
@interface CMAUser : CDAResource

/**
 *  URL of the user's avatar image.
 */
@property (nonatomic, readonly) NSURL* avatarURL;

/**
 *  First name of the user.
 */
@property (nonatomic, readonly) NSString* firstName;

/**
 *  Last name of the user.
 */
@property (nonatomic, readonly) NSString* lastName;

@end
