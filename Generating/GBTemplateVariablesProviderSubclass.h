//
//  GBTemplateVariablesProviderSubclass.h
//  appledoc
//
//  Created by Aron Cedercrantz on 11/05/11.
//  Copyright 2011 Gentle Bytes. All rights reserved.
//

#import "GBTemplateVariablesProvider.h"

@class GBStore;
@class GBApplicationSettingsProvider;

#pragma mark -

/** 
 
 */
@interface GBTemplateVariablesProvider ()

- (NSString *)hrefForObject:(id)object fromObject:(id)source;

@end

@interface GBTemplateVariablesProvider (SubclassReadonly)

@property (readonly, retain) GBStore *store;
@property (readonly, retain) GBApplicationSettingsProvider *settings;

@end

