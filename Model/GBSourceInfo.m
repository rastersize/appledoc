//
//  GBSourceInfo.m
//  appledoc
//
//  Created by Tomaz Kragelj on 23.9.10.
//  Copyright (C) 2010, Gentle Bytes. All rights reserved.
//

#import "GBSourceInfo.h"

@interface GBSourceInfo ()

@property (readwrite, copy) NSString *filename;
@property (readwrite, assign) NSUInteger lineNumber;

@end

#pragma mark -

@implementation GBSourceInfo

#pragma mark Initialization & disposal

+ (id)fileDataWithFilename:(NSString *)filename lineNumber:(NSUInteger)lineNumber {
	NSParameterAssert(filename != nil);
	NSParameterAssert([filename length] > 0);
	GBSourceInfo *result = [[[GBSourceInfo alloc] init] autorelease];
	result.filename = filename;
	result.lineNumber = lineNumber;
	return result;
}

#pragma mark Helper methods

- (NSComparisonResult)compare:(GBSourceInfo *)data {
	NSComparisonResult result = [self.filename compare:data.filename];
	if (result == NSOrderedSame) {
		if (data.lineNumber > self.lineNumber) return NSOrderedAscending;
		if (data.lineNumber < self.lineNumber) return NSOrderedDescending;
	}
	return result;
}

#pragma mark Overriden methods

- (NSString *)description {
	return [NSString stringWithFormat:@"%@{ %@ @%ld }", [self className], self.filename, self.lineNumber];
}

#pragma mark Properties

@synthesize filename;
@synthesize lineNumber;

@end