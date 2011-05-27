//
//  GBLatexTemplateVariableProvider.m
//  appledoc
//
//  Created by Aron Cedercrantz on 11/05/11.
//  Copyright 2011 Gentle Bytes. All rights reserved.
//

#import "GBLatexTemplateVariablesProvider.h"
#import "GBTemplateVariablesProviderSubclass.h"
#import "GBApplicationSettingsProvider.h"
#import "GBDataObjects.h"
#import "GBStore.h"

@interface GBLatexTemplateVariablesProvider ()

- (NSDictionary *)dictionaryByEscapingLatex:(NSDictionary *)dictionary;

@end

#pragma mark -

@implementation GBLatexTemplateVariablesProvider

#pragma mark Object variables handling

- (NSDictionary *)variablesForIndexWithStore:(id)store
{
	NSDictionary *vars = [super variablesForIndexWithStore:store];
	NSDictionary *cleanVars = [self dictionaryByEscapingLatex:vars];
	
	return cleanVars;
}

- 

#pragma mark Helpers methods

- (NSString *)hrefForObject:(id)object fromObject:(id)source {
	if (!object) return nil;
	if ([object isKindOfClass:[GBClassData class]] && ![[self.store classes] containsObject:object]) return nil;
	if ([object isKindOfClass:[GBCategoryData class]] && ![[self.store categories] containsObject:object]) return nil;
	if ([object isKindOfClass:[GBProtocolData class]] && ![[self.store protocols] containsObject:object]) return nil;
	return [self.settings latexReferenceForObject:object fromSource:source];
}

- (NSDictionary *)dictionaryByEscapingLatex:(NSDictionary *)dictionary {
	NSMutableDictionary *cleanDictionary = [[NSMutableDictionary alloc] initWithCapacity:[vars count]];
	[dictionary enumerateKeysAndObjectsUsingBlock:
	 ^(id key, id obj, BOOL *stop) {
		 [cleanVars setObject:[self.settings stringByEscapingLatex:((NSString *)obj)] forKey:key];
	 }];
	
	return cleanDictionary;
}

@end
