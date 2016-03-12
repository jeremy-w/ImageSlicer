//: Playground - noun: a place where people can play

//: Copyright (c) 2016 Jeremy W. Sherman. Released with NO WARRANTY.
//:
//: This Source Code Form is subject to the terms of the Mozilla Public
//: License, v. 2.0. If a copy of the MPL was not distributed with this
//: file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Cocoa

var str = "Hello, playground"

enum Orientation {
    case Horizontally
    case Vertically
}

struct Cut {
    let at: CGPoint
    let oriented: Orientation

    func slice(subimage: Subimage) -> [Subimage] {
        let edge: CGRectEdge
        let amount: CGFloat

        switch oriented {
        case .Horizontally:
            edge = .MinYEdge
            amount = at.y - CGRectGetMinY(subimage.rect)
        case .Vertically:
            edge = .MinXEdge
            amount = at.x - CGRectGetMinX(subimage.rect)
        }

        var subrect = CGRectZero
        var otherSubrect = CGRectZero
        CGRectDivide(subimage.rect, &subrect, &otherSubrect, amount, edge)
        return [subrect, otherSubrect].map(Subimage.init)
    }
}

struct Subimage {
    let rect: CGRect

    func contains(point: CGPoint) -> Bool {
        return CGRectContainsPoint(rect, point)
    }
}

struct Mark {
    let around: CGPoint
    let name: String
}

struct Job {
    let image: NSImage
    var cuts: [Cut]
    var selections: [Mark]

    mutating func add(cut: Cut) {
        cuts.append(cut)
    }

    var subimages: [Subimage] {
        var subimages = [Subimage(
            rect: CGRect(origin: CGPointZero, size: image.size))]

        for cut in cuts {
            let at = cut.at
            let index = subimages.indexOf({ $0.contains(at) })!
            let withinSubimage = subimages[index]

            let children = cut.slice(withinSubimage)
            subimages.replaceRange(Range(start: index, end: index + 1), with: children)
        }

        return subimages
    }

    /// - returns: the file URLs created
    func exportSelectedSubimages(directory: NSURL, dryRun: Bool) -> [NSURL] {
        var created: [NSURL] = []

        let subimages = self.subimages
        selections.forEach { selection in
            guard let index = subimages.indexOf({ $0.contains(selection.around) }) else {
                NSLog("\(__FUNCTION__): error: selection \(selection) not contained by any subimage!")
                return
            }

            let subimage = subimages[index]
            guard let bitmap = bitmapFor(subimage) else {
                return
            }

            let fileURL = directory.URLByAppendingPathComponent("\(selection.name).png", isDirectory: false)

            guard !dryRun else {
                created.append(fileURL)
                return
            }

            let data = bitmap.representationUsingType(.NSPNGFileType, properties: [:])
            do {
                try data?.writeToURL(fileURL, options: .DataWritingWithoutOverwriting)
                created.append(fileURL)
            } catch {
                NSLog("\(__FUNCTION__): error: failed writing \(data?.length) bytes to file \(fileURL.absoluteURL.path): \(error)")
            }
        }

        NSLog("created: \(created)")
        return created
    }


    func bitmapFor(subregion: Subimage) -> NSBitmapImageRep? {
        let subregion = CGRectIntegral(subregion.rect)
        let size = subregion.size
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(subregion.size.width), pixelsHigh: Int(subregion.size.height),
            bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false,
            colorSpaceName: NSCalibratedRGBColorSpace,
            bytesPerRow: 4*Int(subregion.size.width), bitsPerPixel: 32) else {
                NSLog("\(__FUNCTION__): error: failed to create bitmap image rep")
                return nil
        }

        let bitmapContext = NSGraphicsContext(bitmapImageRep: bitmap)

        let old = NSGraphicsContext.currentContext()
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.setCurrentContext(bitmapContext)

        let target = CGRect(origin: CGPointZero, size: size)
        image.drawInRect(
            target,
            fromRect: subregion,
            operation: .CompositeCopy,
            fraction: 1.0,
            respectFlipped: true, hints: nil)

        NSGraphicsContext.setCurrentContext(old)
        NSGraphicsContext.restoreGraphicsState()

        return bitmap
    }
}


class ImageSliceJobView: NSView {
    var job: Job
    init(job: Job) {
        self.job = job
        let frame = CGRect(origin: CGPointZero, size: job.image.size)
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawRect(dirtyRect: NSRect) {
        job.image.drawInRect(self.bounds)

        NSColor.greenColor().set()
        outlineSubimages()

        NSColor.redColor().set()
        markCutPoints()

        labelSelections(NSColor.blueColor())
    }


    func outlineSubimages() {
        for sub in job.subimages {
            NSFrameRect(sub.rect)
        }
    }


    func markCutPoints() {
        for cut in job.cuts {
            let rect = CGRect(origin: cut.at, size: CGSize(width: 2, height: 2))
            NSRectFill(CGRectOffset(rect, -1, -1))
        }
    }


    func labelSelections(textColor: NSColor) {
        let attributes = [NSForegroundColorAttributeName: textColor]
        for selection in job.selections {
            let text = selection.name
            text.drawAtPoint(selection.around, withAttributes: attributes)
        }
    }
}

//: Basic image
let image = NSImage(named: "fourpart.gif")!

//: Split between English and Gregg
var job = Job(image: image, cuts: [], selections: [])
job.add(
    Cut(at: CGPoint(x: 20, y: image.size.height - 18),
        oriented: .Horizontally))
job.add(Cut(at: CGPoint(x: 75, y: 0), oriented: .Vertically))
job.add(Cut(at: CGPoint(x: 155, y: 0), oriented: .Vertically))
job.add(Cut(at: CGPoint(x: 235, y: 0), oriented: .Vertically))
job.selections.append(Mark(around: CGPointZero, name: "deed"))
job.selections.append(Mark(around: CGPoint(x: 80, y: 0), name: "dad"))

var display = ImageSliceJobView(job: job)

//: Dry-run of exporting should list an image per mark
job.exportSelectedSubimages(NSURL(fileURLWithPath: NSHomeDirectory(), isDirectory: true), dryRun: true)
