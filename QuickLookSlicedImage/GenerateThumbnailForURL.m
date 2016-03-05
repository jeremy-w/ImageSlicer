//  Copyright © 2016 Jeremy W. Sherman. Released with NO WARRANTY.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

@import Foundation;
@import CoreServices;
@import QuickLook;
#import "QuickLookSlicedImage-Swift.h"

OSStatus GenerateThumbnailForURL(
    void *thisInterface,
    QLThumbnailRequestRef request,
    CFURLRef url,
    CFStringRef contentTypeUTI,
    CFDictionaryRef options,
    CGSize maxSize
);
void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail);


OSStatus
GenerateThumbnailForURL(
    void *thisInterface,
    QLThumbnailRequestRef request,
    CFURLRef url,
    CFStringRef contentTypeUTI,
    CFDictionaryRef options,
    CGSize maxSize)
{
    @autoreleasepool {
        Thumbnail *thumbnail = [[Thumbnail alloc]
                                initWithURL:CFBridgingRelease(url)
                                contentType:CFBridgingRelease(contentTypeUTI)
                                options:CFBridgingRelease(options)];
        [thumbnail makeThumbnailAtMost:maxSize with:request];
    }
    return noErr;
}


void
CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef request)
{
    // Implement only if supported
}
