//  Copyright © 2016 Jeremy W. Sherman. Released with NO WARRANTY.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Cocoa
import QuickLook

class Thumbnail: NSObject {
    let document: Document

    @objc
    init?(withURL url: NSURL, contentType UTI: String) {
        guard let document = try? Document(contentsOfURL: url, ofType: UTI) else {
            self.document = Document()
            super.init()
            return nil
        }
        self.document = document
        super.init()
    }

    @objc
    func makeThumbnail(atMost size: CGSize, with request: QLThumbnailRequestRef, options: NSDictionary) {
        guard let view = JobView(job: document.job) else {
            NSLog("\(self): failed to create job view for job: \(document.job) - document: \(document)")
            return
        }

        let rect = view.bounds
        let forDrawingBitmap = true
        let properties = NSDictionary()
        guard let unmanagedContext = QLThumbnailRequestCreateContext(request, rect.size, forDrawingBitmap, properties)  else {
            NSLog("\(self): failed to create drawing context with size \(rect.size) - document: \(document)")
            return
        }

        let rawContext = unmanagedContext.takeRetainedValue()
        let context = NSGraphicsContext(CGContext: rawContext, flipped: true)
        view.displayRectIgnoringOpacity(rect, inContext: context)
        QLThumbnailRequestFlushContext(request, rawContext)
    }
}
