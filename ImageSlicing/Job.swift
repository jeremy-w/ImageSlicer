//  Copyright © 2016 Jeremy W. Sherman. Released with NO WARRANTY.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Cocoa

class Job {
    var image: NSImage?
    var cuts: [Cut]
    var selections: [Mark]
    var undoing: Undoing?

    init(image: NSImage?, cuts: [Cut] = [], selections: [Mark] = []) {
        self.image = image
        self.cuts = cuts
        self.selections = selections
    }

    func add(cut: Cut, index: Int? = nil) {
        let target = index ?? cuts.count
        cuts.insert(cut, atIndex: target)
        undo(NSLocalizedString("Add Cut", comment: "job action")) {
            $0.removeCutAt(target)
        }
    }

    func remove(cut: Cut) {
        guard let index = cuts.indexOf(cut) else {
            NSLog("%@", "\(#function): Ignoring request to remove absent cut \(cut)")
            return
        }

        removeCutAt(index)
    }

    func removeCutAt(index: Int) {
        let cut = cuts.removeAtIndex(index)
        undo(NSLocalizedString("Delete Cut", comment: "job action")) {
            $0.add(cut, index: index)
        }
    }

    func add(mark: Mark, index: Int? = nil) {
        let target = index ?? selections.count
        selections.insert(mark, atIndex: target)
        undo(NSLocalizedString("Add Mark", comment: "job action")) {
            $0.removeMarkAt(target)
        }
    }

    func remove(mark: Mark) {
        guard let index = selections.indexOf(mark) else {
            NSLog("%@", "\(#function): Ignoring request to remove absent mark \(mark)")
            return
        }

        removeMarkAt(index)
    }

    func removeMarkAt(index: Int) {
        let mark = selections.removeAtIndex(index)
        undo(NSLocalizedString("Delete Mark", comment: "job action")) {
            $0.add(mark, index: index)
        }
    }

    var subimages: [Subimage] {
        guard let image = image else {
            return []
        }

        var subimages = [Subimage(
            rect: CGRect(origin: CGPointZero, size: image.size))]

        for cut in cuts {
            let at = cut.at
            let index = subimages.indexOf({ $0.contains(at) })!
            let withinSubimage = subimages[index]

            let children = cut.slice(withinSubimage)
            subimages.replaceRange(index ..< (index + 1), with: children)
        }

        return subimages
    }

    func rename(mark: Mark, to name: String) {
        guard let index = selections.indexOf(mark) else { return }
        let oldMark = selections[index]
        let renamedMark = Mark(around: oldMark.around, name: name)
        let markRange = index ..< (index + 1)
        selections.replaceRange(markRange, with: [renamedMark])

        let actionName = NSLocalizedString("Rename Mark", comment: "job action")
        undo(actionName) {
            $0.selections.replaceRange(markRange, with: [oldMark])
            $0.undo(actionName) {
                $0.selections.replaceRange(markRange, with: [renamedMark])
            }
        }
    }

    /// - returns: the file URLs created
    func exportSelectedSubimages(directory: NSURL, dryRun: Bool) -> [NSURL] {
        var created: [NSURL] = []

        let subimages = self.subimages
        selections.forEach { selection in
            guard let index = subimages.indexOf({ $0.contains(selection.around) }) else {
                NSLog("%@", "\(#function): error: selection \(selection) not contained by any subimage!")
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
                NSLog("%@", "\(#function): error: failed writing \(data?.length) bytes to file \(fileURL.absoluteURL.path): \(error)")
            }
        }

        NSLog("%@", "created: \(created)")
        return created
    }


    func bitmapFor(subregion: Subimage) -> NSBitmapImageRep? {
        guard let image = image else {
            return nil
        }

        let subregion = CGRectIntegral(subregion.rect)
        let size = subregion.size
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(subregion.size.width), pixelsHigh: Int(subregion.size.height),
            bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false,
            colorSpaceName: NSCalibratedRGBColorSpace,
            bytesPerRow: 4*Int(subregion.size.width), bitsPerPixel: 32) else {
                NSLog("%@", "\(#function): error: failed to create bitmap image rep")
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


// MARK: - Undo
extension Job {
    func undo(actionName: String, closure: (Job) -> Void) {
        guard let undoing = undoing else { return }
        undoing.record(actionName) { [weak self] in
            guard let me = self else { return }
            closure(me)
        }
    }
}


// MARK: - De/Serialization
extension Job {
    class Keys {
        static let Image = "image"
        static let Cuts = "cuts"
        static let Selections = "selections"
    }

    var asDictionary: [String: AnyObject] {
        var dictionary: [String: AnyObject] = [:]
        if let image = image {
            dictionary[Keys.Image] = image
        }

        dictionary[Keys.Cuts] = cuts.map { $0.asDictionary }
        dictionary[Keys.Selections] = selections.map { $0.asDictionary }
        NSLog("%@", "\(#function): pickled \(self): \(dictionary)")
        return dictionary
    }

    convenience init?(dictionary: [String: AnyObject]) {
        NSLog("%@", "\(#function): unpickling: \(dictionary)")
        var actualImage: NSImage?

        let maybeValue = dictionary[Keys.Image]
        if let value = maybeValue {
            guard let image = value as? NSImage else {
                return nil
            }

            actualImage = image
        }

        guard let cutDicts = dictionary[Keys.Cuts] as? [[String: AnyObject]] else {
            return nil
        }
        let cuts = cutDicts.flatMap { Cut(dictionary: $0) }
        guard cuts.count == cutDicts.count else {
            return nil
        }


        guard let selectionDicts = dictionary[Keys.Selections] as? [[String: AnyObject]] else {
            return nil
        }
        let selections = selectionDicts.flatMap { Mark(dictionary: $0) }
        guard selections.count == selectionDicts.count else {
            return nil
        }

        self.init(image: actualImage, cuts: cuts, selections: selections)
    }
}
