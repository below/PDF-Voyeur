/* Voyeur - VoyeurDocument.m
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

#import "VoyeurDocument.h"
#import "VoyeurDataSource.h"

NSString *VoyeurNodeChangedNotification = @"VoyeurNodeChangedNotification";

@implementation VoyeurDocument

- (id)init
{
    self = [super init];
    if (self == nil)
	return nil;

    [(NSNotificationCenter *)[NSNotificationCenter defaultCenter]
	addObserver:self selector:@selector(selectionChanged:)
	name:NSOutlineViewSelectionDidChangeNotification object:outlineView];

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    CGPDFDocumentRelease(document);
    [dataSource release];
    [super dealloc];
}

- (NSString *)windowNibName
{
    /* Override returning the nib file name of the document. If you need to
     * use a subclass of NSWindowController or if your document supports
     * multiple NSWindowControllers, you should remove this method and
     * override -makeWindowControllers instead. */
    
    return @"VoyeurDocument";
}

/* CFDataRef data provider support. */

static const void *
getCFDataBytePointer(void *info)
{
    CFDataRef data;

    data = info;
    return CFDataGetBytePtr(data);
}

static void
releaseCFData(void *info)
{
    CFDataRef data;

    data = info;
    CFRelease(data);
}

/* Create a direct-access data provider using `data', a CFDataRef. */

static CGDataProviderRef
dataProviderWithCFData(CFDataRef data)
{
    void *info;
    size_t size;
    static const CGDataProviderDirectCallbacks callbacks = {
		0, 
	&getCFDataBytePointer, NULL, NULL, &releaseCFData
    };

    if (data == NULL)
	return NULL;

    size = CFDataGetLength(data);
    info = (void *)CFRetain(data);
    return CGDataProviderCreateDirect (info, size, &callbacks);
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)type
{
    CGDataProviderRef provider;

    if ([type isEqualToString:@"PDFType"]) {
	provider = dataProviderWithCFData((CFDataRef)data);
	if (data == NULL)
	    return NO;
	document = CGPDFDocumentCreateWithProvider(provider);
	if (document == NULL) {
	    CGDataProviderRelease(provider);
	    return NO;
	}
	CGDataProviderRelease(provider);
	return YES;
    }

    return NO;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)controller
{
    [super windowControllerDidLoadNib:controller];
	[self loadDocumentInfo];
    dataSource = [[VoyeurDataSource alloc] initWithDocument:document];
    [outlineView setDataSource:dataSource];
}

- (VoyeurNode *)selectedNode
{
    return selectedNode;
}

- (VoyeurDataSource *)dataSource
{
	return dataSource;
}

static void
setCGPDFStringValue(NSTextField *field, CGPDFStringRef string)
{
    CFStringRef s;

    s = CGPDFStringCopyTextString(string);
    if (s != NULL) {
	[field setStringValue:(NSString *)s];
	CFRelease(s);
    }
}

static void
setCGPDFStringValueAsDate(NSTextField *field, CGPDFStringRef string)
{
    CFDateRef date;

    date = CGPDFStringCopyDate(string);
    if (date != NULL) {
	[field setStringValue:[(NSDate *)date description]];
	CFRelease(date);
    }
}

- (void)loadDocumentInfo
{
    CGPDFStringRef string;
    CGPDFDictionaryRef infoDict;
    int majorVersion, minorVersion;

    CGPDFDocumentGetVersion(document, &majorVersion, &minorVersion);
    [versionField setStringValue:
	[NSString stringWithFormat:@"%d.%d", majorVersion, minorVersion]];
    [encryptedField setStringValue:
	CGPDFDocumentIsEncrypted(document) ? @"Yes" : @"No"];
    [pagesField setIntValue:CGPDFDocumentGetNumberOfPages(document)];
	
    infoDict = CGPDFDocumentGetInfo(document);
    if (CGPDFDictionaryGetString(infoDict, "Title", &string))
	setCGPDFStringValue(titleField, string);
    if (CGPDFDictionaryGetString(infoDict, "Author", &string))
	setCGPDFStringValue(authorField, string);
    if (CGPDFDictionaryGetString(infoDict, "Subject", &string))
	setCGPDFStringValue(subjectField, string);
    if (CGPDFDictionaryGetString(infoDict, "Keywords", &string))
	setCGPDFStringValue(keywordsField, string);
    if (CGPDFDictionaryGetString(infoDict, "Creator", &string))
	setCGPDFStringValue(creatorField, string);
    if (CGPDFDictionaryGetString(infoDict, "Producer", &string))
	setCGPDFStringValue(producerField, string);
    if (CGPDFDictionaryGetString(infoDict, "CreationDate", &string))
	setCGPDFStringValueAsDate(createdField, string);
    if (CGPDFDictionaryGetString(infoDict, "ModDate", &string))
	setCGPDFStringValueAsDate(modifiedField, string);
}

- (void)selectionChanged:(NSNotification *)notification
{
    int row;
    
    row = [[notification object] selectedRow];
    selectedNode = [[notification object] itemAtRow:row];
    if (![selectedNode isKindOfClass:[VoyeurNode class]])
	selectedNode = nil;

    [(NSNotificationCenter *)[NSNotificationCenter defaultCenter]
	postNotificationName:VoyeurNodeChangedNotification
	 object:selectedNode userInfo:nil];
}

@end
