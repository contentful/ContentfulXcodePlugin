//
//  Tests.m
//  Tests
//
//  Created by Boris Bügling on 10/11/14.
//  Copyright (c) 2014 Contentful GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ContentfulDeliveryAPI/ContentfulDeliveryAPI.h>
#import <XCTest/XCTest.h>

#import "AsyncTesting.h"
#import "ContentfulModelGenerator.h"

@interface Tests : XCTestCase

@end

#pragma mark -

@implementation Tests

- (void)testExample {
    CDAClient* client = [[CDAClient alloc] initWithSpaceKey:@"a3rsszoo7qqp" accessToken:@"57a1ef74e87e234bed4d3f932ec945a82dae641d6ea2b2435ea2837de94d6be5"];
    ContentfulModelGenerator* generator = [[ContentfulModelGenerator alloc] initWithClient:client];

    StartBlock();

    [generator generateModelForContentTypesWithCompletionHandler:^(NSManagedObjectModel* model,
                                                                   NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(2U, model.entities.count, @"");

        EndBlock();
    }];

    WaitUntilBlockCompletes();
}

@end
