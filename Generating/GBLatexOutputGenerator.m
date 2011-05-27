//
//  GBLatexOutputGenerator.m
//  appledoc
//
//  Created by Aron Cedercrantz on 11/05/11.
//  Copyright 2011 Aron Cedercrantz & Gentle Bytes. All rights reserved.
//

#import "GBLatexOutputGenerator.h"
#import "GBStore.h"
#import "GBApplicationSettingsProvider.h"
#import "GBDataObjects.h"
#import "GBLatexTemplateVariablesProvider.h"
#import "GBTemplateHandler.h"
#import "GBHTMLOutputGenerator.h"


@interface GBLatexOutputGenerator ()

- (BOOL)validateTemplates:(NSError **)error;
- (BOOL)processClasses:(NSError **)error;
- (BOOL)processCategories:(NSError **)error;
- (BOOL)processProtocols:(NSError **)error;
- (BOOL)processDocuments:(NSError **)error;
- (BOOL)processIndex:(NSError **)error;
- (BOOL)processHierarchy:(NSError **)error;
- (NSString *)stringCleanedForLatex:(NSString *)string;
- (NSString *)latexOutputPathForIndex;
- (NSString *)latexOutputPathForHierarchy;
- (NSString *)latexOutputPathForObject:(GBModelBase *)object;
- (NSString *)latexOutputPathForTemplateName:(NSString *)template;
@property (readonly) GBTemplateHandler *latexObjectTemplate;
@property (readonly) GBTemplateHandler *latexIndexTemplate;
@property (readonly) GBTemplateHandler *latexHierarchyTemplate;
@property (readonly) GBTemplateHandler *latexDocumentTemplate;
@property (readonly) GBLatexTemplateVariablesProvider *variablesProvider;

@end

#pragma mark -

@implementation GBLatexOutputGenerator

#pragma Generation handling

- (BOOL)generateOutputWithStore:(id)store error:(NSError **)error
{
	if (![super generateOutputWithStore:store error:error]) return NO;
	if (![self validateTemplates:error]) return NO;
	if (![self processClasses:error]) return NO;
	if (![self processCategories:error]) return NO;
	if (![self processProtocols:error]) return NO;
	if (![self processDocuments:error]) return NO;
	if (![self processIndex:error]) return NO;
	if (![self processHierarchy:error]) return NO;
	return YES;
}

- (BOOL)processClasses:(NSError **)error
{
	for (GBClassData *class in self.store.classes) {
		GBLogInfo(@"Generating LaTeX output for class %@...", class);
		NSDictionary *vars = [self.variablesProvider variablesForClass:class withStore:self.store];
		NSString *output = [self.latexObjectTemplate renderObject:vars];
		NSString *cleaned = [self stringCleanedForLatex:output];
		NSString *path = [self latexOutputPathForObject:class];
		if (![self writeString:cleaned toFile:[path stringByStandardizingPath] error:error]) {
			GBLogWarn(@"Failed writing LaTeX for class %@ to '%@'!", class, path);
			return NO;
		}
		GBLogDebug(@"Finished generating LaTeX output for class %@.", class);
	}
	return YES;
}

- (BOOL)processCategories:(NSError **)error
{
	for (GBCategoryData *category in self.store.categories) {
		GBLogInfo(@"Generating LaTeX output for category %@...", category);
		NSDictionary *vars = [self.variablesProvider variablesForCategory:category withStore:self.store];
		NSString *output = [self.latexObjectTemplate renderObject:vars];
		NSString *cleaned = [self stringCleanedForLatex:output];
		NSString *path = [self latexOutputPathForObject:category];
		if (![self writeString:cleaned toFile:[path stringByStandardizingPath] error:error]) {
			GBLogWarn(@"Failed writing LaTeX for category %@ to '%@'!", category, path);
			return NO;
		}
		GBLogDebug(@"Finished generating LaTeX output for category %@.", category);
	}
	return YES;
}

- (BOOL)processProtocols:(NSError **)error
{
	for (GBProtocolData *protocol in self.store.protocols) {
		GBLogInfo(@"Generating LaTeX output for protocol %@...", protocol);
		NSDictionary *vars = [self.variablesProvider variablesForProtocol:protocol withStore:self.store];
		NSString *output = [self.latexObjectTemplate renderObject:vars];
		NSString *cleaned = [self stringCleanedForLatex:output];
		NSString *path = [self latexOutputPathForObject:protocol];
		if (![self writeString:cleaned toFile:[path stringByStandardizingPath] error:error]) {
			GBLogWarn(@"Failed writing LaTeX for protocol %@ to '%@'!", protocol, path);
			return NO;
		}
		GBLogDebug(@"Finished generating LaTeX output for protocol %@.", protocol);
	}
	return YES;
}

- (BOOL)processIndex:(NSError **)error {
	GBLogInfo(@"Generating LaTeX output for index...");
	if ([self.store.classes count] > 0 || [self.store.protocols count] > 0 || [self.store.categories count] > 0) {
		NSDictionary *vars = [self.variablesProvider variablesForIndexWithStore:self.store];
		NSString *output = [self.latexIndexTemplate renderObject:vars];
		NSString *cleaned = [self stringCleanedForLatex:output];
		NSString *path = [[self latexOutputPathForIndex ] stringByStandardizingPath];
		if (![self writeString:cleaned toFile:path error:error]) {
			GBLogWarn(@"Failed writting LaTeX index to '%@'!", path);
			return NO;
		}
	}
	GBLogDebug(@"Finished generating LaTeX output for index.");
	return YES;
}

- (BOOL)processHierarchy:(NSError **)error {
	GBLogInfo(@"Generating LaTeX output for hierarchy...");
	if ([self.store.classes count] > 0 || [self.store.protocols count] > 0 || [self.store.categories count] > 0) {
		NSDictionary *vars = [self.variablesProvider variablesForHierarchyWithStore:self.store];
		NSString *output = [self.latexHierarchyTemplate renderObject:vars];
		NSString *cleaned = [self stringCleanedForLatex:output];
		NSString *path = [[self latexOutputPathForHierarchy] stringByStandardizingPath];
		if (![self writeString:cleaned toFile:path error:error]) {
			GBLogWarn(@"Failed writting LaTeX hierarchy to '%@'!", path);
			return NO;
		}
	}
	GBLogDebug(@"Finished generating LaTeX output for hierarchy.");
	return YES;
}

- (BOOL)processDocuments:(NSError **)error {	
	// First process all include paths by copying them over to the destination. Note that we do it even if no template is found - if the user specified some include path, we should use it...
	NSString *docsUserPath = [self.outputUserPath stringByAppendingPathComponent:self.settings.latexStaticDocumentsSubpath];
	GBTemplateFilesHandler *handler = [[GBTemplateFilesHandler alloc] init];
	for (NSString *path in self.settings.includePaths) {
		GBLogInfo(@"Copying static LaTeX documents from '%@'...", path);
		NSString *lastComponent = [path lastPathComponent];
		NSString *installPath = [docsUserPath stringByAppendingPathComponent:lastComponent];
		handler.templateUserPath = path;
		handler.outputUserPath = installPath;
		if (![handler copyTemplateFilesToOutputPath:error]) return NO;
	}
	
	// Now process all documents.
	for (GBDocumentData *document in self.store.documents) {
		GBLogInfo(@"Generating LaTeX output for document %@...", document);
		NSDictionary *vars = [self.variablesProvider variablesForDocument:document withStore:self.store];
		NSString *output = [self.latexDocumentTemplate renderObject:vars];
		NSString *cleaned = [self stringCleanedForLatex:output];
		NSString *path = [self latexOutputPathForObject:document];
		if (![self writeString:cleaned toFile:[path stringByStandardizingPath] error:error]) {
			GBLogWarn(@"Failed writting LaTeX for document %@ to '%@'!", document, path);
			return NO;
		}
		GBLogDebug(@"Finished generating LaTeX output for document %@.", document);
	}
	return YES;
}

- (BOOL)validateTemplates:(NSError **)error
{
	if (!self.latexObjectTemplate) {
		if (error) {
			NSString *desc = [NSString stringWithFormat:@"Object template file 'object-template.tex' is missing at '%@'!", self.templateUserPath];
			*error = [NSError errorWithCode:GBErrorLatexObjectTemplateMissing description:desc reason:nil];
		}
		return NO;
	}
	if (!self.latexDocumentTemplate) {
		if (error) {
			NSString *desc = [NSString stringWithFormat:@"Document template file 'document-template.tex' is missing at '%@'!", self.templateUserPath];
			*error = [NSError errorWithCode:GBErrorLatexDocumentTemplateMissing description:desc reason:nil];
		}
		return NO;
	}
	if (!self.latexIndexTemplate) {
		if (error) {
			NSString *desc = [NSString stringWithFormat:@"Index template file 'index-template.tex' is missing at '%@'!", self.templateUserPath];
			*error = [NSError errorWithCode:GBErrorLatexIndexTemplateMissing description:desc reason:nil];
		}
		return NO;
	}
	if (!self.latexHierarchyTemplate) {
		if (error) {
			NSString *desc = [NSString stringWithFormat:@"Hierarchy template file 'hierarchy-template.tex' is missing at '%@'!", self.templateUserPath];
			*error = [NSError errorWithCode:GBErrorLatexHierarchyTemplateMissing description:desc reason:nil];
		}
		return NO;
	}
	
	return YES;
}

#pragma mark Helper methods

- (NSString *)stringCleanedForLatex:(NSString *)string
{
	// Copied directly from GRMustache's GRMustacheVariableElement.m...
	NSMutableString *result = [NSMutableString stringWithCapacity:5 + ceilf(string.length * 1.1)];
	[result appendString:string];
	
	// Restore thing that might have been escaped for HTML
	[result replaceOccurrencesOfString:@"&amp;" withString:@"\\&" options:NSLiteralSearch range:NSMakeRange(0, result.length)];
	[result replaceOccurrencesOfString:@"&lt;" withString:@"<" options:NSLiteralSearch range:NSMakeRange(0, result.length)];
	[result replaceOccurrencesOfString:@"&gt;" withString:@">" options:NSLiteralSearch range:NSMakeRange(0, result.length)];
	[result replaceOccurrencesOfString:@"&quot;" withString:@"\"" options:NSLiteralSearch range:NSMakeRange(0, result.length)];
	[result replaceOccurrencesOfString:@"&apos;" withString:@"'" options:NSLiteralSearch range:NSMakeRange(0, result.length)];
	
	return result;
}

- (NSString *)latexOutputPathForIndex {
	// Returns file name including full path for LaTeX file representing the main index.
	return [self latexOutputPathForTemplateName:@"index-template.tex"];
}

- (NSString *)latexOutputPathForHierarchy {
	// Returns file name including full path for HTML file representing the main hierarchy.
	return [self latexOutputPathForTemplateName:@"hierarchy-template.tex"];
}

- (NSString *)latexOutputPathForTemplateName:(NSString *)template {
	// Returns full path and actual file name corresponding to the given template.
	NSString *path = [self outputPathToTemplateEndingWith:template];
	NSString *filename = [self.settings outputFilenameForTemplatePath:template];
	return [path stringByAppendingPathComponent:filename];
}

- (NSString *)latexOutputPathForObject:(GBModelBase *)object
{
	// Returns file name including full path for LaTeX file representing the given top-level object. This works for any top-level object: class, category or protocol. The path is automatically determined regarding to the object class. Note that we use the HTML reference to get us the actual path - we can't rely on template filename as it's the same for all objects...
	NSString *inner = [self.settings latexReferenceForObjectFromIndex:object];
	return [self.outputUserPath stringByAppendingPathComponent:inner];
}

- (GBLatexTemplateVariablesProvider *)variablesProvider {
	static GBLatexTemplateVariablesProvider *result = nil;
	if (!result) {
		GBLogDebug(@"Initializing variables provider...");
		result = [[GBLatexTemplateVariablesProvider alloc] initWithSettingsProvider:self.settings];
	}
	return result;
}

- (GBTemplateHandler *)latexObjectTemplate {
	return [self.templateFiles objectForKey:@"object-template.tex"];
}

- (GBTemplateHandler *)latexIndexTemplate {
	return [self.templateFiles objectForKey:@"index-template.tex"];
}

- (GBTemplateHandler *)latexHierarchyTemplate {
	return [self.templateFiles objectForKey:@"hierarchy-template.tex"];
}

- (GBTemplateHandler *)latexDocumentTemplate {
	return [self.templateFiles objectForKey:@"document-template.tex"];
}

#pragma mark Overriden methods

- (NSString *)outputSubpath {
	return @"latex";
}

@end
