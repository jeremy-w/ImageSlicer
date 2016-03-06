//  Copyright © 2016 Jeremy W. Sherman. Released with NO WARRANTY.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Cocoa
import QuickLook


class QuickLook: NSObject {
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
    func renderThumbnail(thumbnail: QLThumbnailRequestRef) {
        render(into: thumbnail)
    }


    @objc
    func renderPreview(preview: QLPreviewRequestRef) {
        render(into: preview)
    }


    func render(into contextProvider: GraphicsContextProvider) {
        guard let view = JobView(job: document.job) else {
            NSLog("\(self): failed to create job view for job: \(document.job) - document: \(document)")
            return
        }

        let rect = view.bounds
        guard let unmanagedContext = contextProvider.createContext(covering: rect.size, forDrawing: .Bitmap)  else {
            NSLog("\(self): failed to create drawing context with size \(rect.size) - document: \(document)")
            return
        }

        let rawContext = unmanagedContext.takeRetainedValue()
        let context = NSGraphicsContext(CGContext: rawContext, flipped: true)
        view.displayRectIgnoringOpacity(rect, inContext: context)
        contextProvider.flush(rawContext)
    }
}



enum RenderingIntent {
    case Vector
    case Bitmap

    /// Bool is apparently not usable as a raw value, so we have this, instead.
    var rawValue: Bool {
        switch self {
        case .Vector: return false
        case .Bitmap: return true
        }
    }
}



// MARK: - GraphicsContextProvider
/// Provides a unified interface to the needed thumbnail and preview methods.
protocol GraphicsContextProvider {
    func createContext(covering size: CGSize, forDrawing: RenderingIntent) -> Unmanaged<CGContext>?
    func flush(context: CGContext)
    var isCanceled: Bool { get }
}



extension QLThumbnailRequestRef: GraphicsContextProvider {
    func createContext(covering size: CGSize, forDrawing intent: RenderingIntent) -> Unmanaged<CGContext>? {
        let properties = NSDictionary()
        let unmanagedContext = QLThumbnailRequestCreateContext(self, size, intent.rawValue, properties)
        return unmanagedContext
    }


    func flush(context: CGContext) {
        QLThumbnailRequestFlushContext(self, context)
    }


    var isCanceled: Bool {
        return QLThumbnailRequestIsCancelled(self)
    }
}



extension QLPreviewRequestRef: GraphicsContextProvider {
    func createContext(covering size: CGSize, forDrawing intent: RenderingIntent) -> Unmanaged<CGContext>? {
        let properties = NSDictionary()
        let unmanagedContext = QLPreviewRequestCreateContext(self, size, intent.rawValue, properties)
        return unmanagedContext
    }


    func flush(context: CGContext) {
        QLPreviewRequestFlushContext(self, context)
    }


    var isCanceled: Bool {
        return QLPreviewRequestIsCancelled(self)
    }
}
