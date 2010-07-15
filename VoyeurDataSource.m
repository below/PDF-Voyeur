/* Voyeur - VoyeurDataSource.m
 *
 * Author: Derek Clegg
 * Created 8 November 2002
 *
 * Copyright (c) 2003-2004 Apple Computer, Inc.
 * All rights reserved.
 */

/* IMPORTANT: This Apple software is supplied to you by Apple Computer,
 Inc. ("Apple") in consideration of your agreement to the following terms,
 and your use, installation, modification or redistribution of this Apple
 software constitutes acceptance of these terms.  If you do not agree with
 these terms, please do not use, install, modify or redistribute this Apple
 software.

 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following text
 and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Computer,
 Inc. may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple. Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.

 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES
 NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE
 IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
 ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT
 LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY
 OF SUCH DAMAGE. */

#import "VoyeurDataSource.h"
#import <AppKit/NSOutlineView.h>
#import <AppKit/NSTableColumn.h>
#import <Foundation/NSString.h>
#import <stdlib.h>

@implementation VoyeurDataSource

- (id)initWithDocument:(CGPDFDocumentRef)pdfDocument
{
    size_t k, count;

    self = [self init];
    if (self == nil)
	return nil;

    fonts = [[FontList alloc] init];
    document = CGPDFDocumentRetain(pdfDocument);
    catalog = CGPDFDocumentGetCatalog(document);
    root = [[VoyeurNode alloc] initWithCatalog:catalog];
	
    count = CGPDFDocumentGetNumberOfPages(document);
    for (k = 0; k < count; k++)
	[fonts addFontsFromPage:CGPDFDocumentGetPage(document, k)];

    return self;
}

- (void)dealloc
{
    [fonts release];
    CGPDFDocumentRelease(document);
    [root release];
    [super dealloc];
}

- (CGPDFDocumentRef)document
{
    return document;
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    VoyeurNode *node;
    NSArray *children;

    node = (item == nil) ? root : item;
    children = [node children];
    if (children == nil)
	return 0;

    return [children count];
}

- (FontList *)fonts
{
    return fonts;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    VoyeurNode *node;
    NSArray *children;

    node = (item == nil) ? root : item;
    children = [node children];
    if (children == nil)
	return nil;
	
    return [children objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    VoyeurNode *node;
    NSArray *children;

    node = (item == nil) ? root : item;
    children = [node children];
    if (children == nil)
	return NO;

    return YES;
}

- (id)outlineView:(NSOutlineView *)outlineView
	objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    VoyeurNode *node;

    node = item;
    if (node == nil)
	abort();

    if ([[tableColumn identifier] isEqualToString:@"Key"])
	return [node name];

    if ([[tableColumn identifier] isEqualToString:@"Value"])
	return [node value];

    if ([[tableColumn identifier] isEqualToString:@"Type"])
	return [node typeAsString];

    return nil;
}

@end
