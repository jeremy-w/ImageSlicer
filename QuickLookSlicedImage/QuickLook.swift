//  Copyright © 2016 Jeremy W. Sherman. Released with NO WARRANTY.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import QuickLook

class Thumbnail: NSObject {
    @objc
    init(withURL url: NSURL, contentType UTI: NSString, options: NSDictionary) {
    }

    @objc
    func makeThumbnail(atMost size: CGSize, with request: QLThumbnailRequestRef) {
    }
}
