//
//  CMALocale.h
//  Pods
//
//  Created by Boris Bügling on 08/08/14.
//
//

#import <ContentfulDeliveryAPI/ContentfulDeliveryAPI.h>

/**
 *  Models the localization of a space into one specific language.
 */
@interface CMALocale : CDAResource

/**
 *  The country-code of the receiver.
 */
@property (nonatomic, readonly) NSString* code;

/**
 *  Whether or not the receiver is the default locale of its space.
 */
@property (nonatomic, readonly, getter = isDefault) BOOL defaultLocale;

/**
 *  The name of the receiver.
 */
@property (nonatomic) NSString* name;

/**
 *  Update the receiver with new values.
 *
 *  @param success Called if the update succeeds.
 *  @param failure Called if the update fails.
 *
 *  @return The request used for updating.
 */
-(CDARequest*)updateWithSuccess:(void (^)())success failure:(CDARequestFailureBlock)failure;

@end
