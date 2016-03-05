//  Copyright © 2016 Jeremy W. Sherman. Released with NO WARRANTY.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

@import Foundation;
@import CoreServices;
@import QuickLook;
#import "QuickLookSlicedImage-Swift.h"

OSStatus GeneratePreviewForURL(
    void *thisInterface,
    QLPreviewRequestRef request,
    CFURLRef url,
    CFStringRef contentTypeUTI,
    CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);


OSStatus
GeneratePreviewForURL(
    void *thisInterface,
    QLPreviewRequestRef request,
    CFURLRef url,
    CFStringRef contentTypeUTI,
    CFDictionaryRef options)
{
    return noErr;
}


void
CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}
