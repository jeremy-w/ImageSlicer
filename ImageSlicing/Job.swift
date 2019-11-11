//  Copyright © 2016 Jeremy W. Sherman. Released with NO WARRANTY.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Cocoa

class Job {
    var imageFrom: URL?
    var image: NSImage?
    var cuts: [Cut]
    var selections: [Mark]
    var undoing: Undoing?

    init(image: NSImage?, cuts: [Cut] = [], selections: [Mark] = []) {
        self.image = image
        self.cuts = cuts
        self.selections = selections
    }

    func add(cut: Cut, at index: Int? = nil) {
        let target = index ?? cuts.count
        cuts.insert(cut, at: target)
        undo(actionName: NSLocalizedString("Add Cut", comment: "job action")) {
            $0.removeCut(at: target)
        }
    }

    func remove(cut: Cut) {
        guard let index = cuts.firstIndex(of: cut) else {
            NSLog("%@", "\(#function): Ignoring request to remove absent cut \(cut)")
            return
        }

        removeCut(at: index)
    }

    func removeCut(at index: Int) {
        let cut = cuts.remove(at: index)
        undo(actionName: NSLocalizedString("Delete Cut", comment: "job action")) {
            $0.add(cut: cut, at: index)
        }
    }

    func add(mark: Mark, at index: Int? = nil) {
        let target = index ?? selections.count
        selections.insert(mark, at: target)
        undo(actionName: NSLocalizedString("Add Mark", comment: "job action")) {
            $0.removeMark(at: target)
        }
    }

    func remove(mark: Mark) {
        guard let index = selections.firstIndex(of: mark) else {
            NSLog("%@", "\(#function): Ignoring request to remove absent mark \(mark)")
            return
        }

        removeMark(at: index)
    }

    func removeMark(at index: Int) {
        let mark = selections.remove(at: index)
        undo(actionName: NSLocalizedString("Delete Mark", comment: "job action")) {
            $0.add(mark: mark, at: index)
        }
    }

    var subimages: [Subimage] {
        guard let image = image else {
            return []
        }

        var subimages = [Subimage(
            rect: CGRect(origin: .zero, size: image.size))]

        for cut in cuts {
            let at = cut.at
            let index = subimages.firstIndex(where: { $0.contains(point: at) })!
            let withinSubimage = subimages[index]

            let children = cut.slice(subimage: withinSubimage)
            subimages.replaceSubrange(index ..< (index + 1), with: children)
        }

        return subimages
    }

    func rename(mark: Mark, to name: String) {
        guard let index = selections.firstIndex(of: mark) else { return }
        let oldMark = selections[index]
        let renamedMark = Mark(around: oldMark.around, name: name)
        let markRange = index ..< (index + 1)
        selections.replaceSubrange(markRange, with: [renamedMark])

        let actionName = NSLocalizedString("Rename Mark", comment: "job action")
        undo(actionName: actionName) {
            $0.selections.replaceSubrange(markRange, with: [oldMark])
            $0.undo(actionName: actionName) {
                $0.selections.replaceSubrange(markRange, with: [renamedMark])
            }
        }
    }

    /// - returns: the file URLs created
    func exportSelectedSubimages(directory: URL, dryRun: Bool) -> [URL] {
        var created: [URL] = []

        let subimages = self.subimages
        selections.forEach { selection in
            guard let index = subimages.firstIndex(where: { $0.contains(point: selection.around) }) else {
                NSLog("%@", "\(#function): error: selection \(selection) not contained by any subimage!")
                return
            }

            let subimage = subimages[index]
            guard let bitmap = bitmapFor(subregion: subimage) else {
                return
            }

            let fileURL = directory.appendingPathComponent("\(selection.name).png", isDirectory: false)

            guard !dryRun else {
                created.append(fileURL)
                return
            }

            let data = bitmap.representation(using: .png, properties: [:])
            do {
                try data?.write(to: fileURL, options: .withoutOverwriting)
                created.append(fileURL)
            } catch {
                NSLog("%@", "\(#function): error: failed writing \(String(describing: data?.count)) bytes to file \(fileURL.absoluteURL.path): \(error)")
            }
        }

        NSLog("%@", "created: \(created)")
        return created
    }


    func bitmapFor(subregion: Subimage) -> NSBitmapImageRep? {
        guard let image = image else {
            return nil
        }

        let subregion = subregion.rect.integral
        let size = subregion.size
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(subregion.size.width), pixelsHigh: Int(subregion.size.height),
            bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 4*Int(subregion.size.width), bitsPerPixel: 32) else {
                NSLog("%@", "\(#function): error: failed to create bitmap image rep")
                return nil
        }

        let bitmapContext = NSGraphicsContext(bitmapImageRep: bitmap)

        let old = NSGraphicsContext.current
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = bitmapContext

        let target = CGRect(origin: .zero, size: size)
        image.draw(
            in: target,
            from: subregion,
            operation: .copy,
            fraction: 1.0,
            respectFlipped: true, hints: nil)
        
        NSGraphicsContext.current = old
        NSGraphicsContext.restoreGraphicsState()
        
        return bitmap
    }
}


// MARK: - Undo
extension Job {
    func undo(actionName: String, closure: @escaping (Job) -> Void) {
        guard let undoing = undoing else { return }
        undoing.record(actionName: actionName) { [weak self] in
            guard let me = self else { return }
            closure(me)
        }
    }
}


// MARK: - De/Serialization
extension Job {
    class Keys {
        static let From = "from"
        static let Image = "image"
        static let Cuts = "cuts"
        static let Selections = "selections"
    }

    var asDictionary: [String: AnyObject] {
        var dictionary: [String: AnyObject] = [:]
        if let imageFrom = imageFrom {
            dictionary[Keys.From] = imageFrom as AnyObject
        }

        if let image = image {
            dictionary[Keys.Image] = image
        }

        dictionary[Keys.Cuts] = cuts.map { $0.asDictionary } as AnyObject
        dictionary[Keys.Selections] = selections.map { $0.asDictionary } as AnyObject
        NSLog("%@", "\(#function): pickled \(self): \(dictionary)")
        return dictionary
    }

    convenience init?(dictionary: [String: AnyObject]) {
        NSLog("%@", "\(#function): unpickling: \(dictionary)")

        let from = dictionary[Keys.From] as? URL

        var image: NSImage? = nil
        if let mustBeNSImageIfPresent = dictionary[Keys.Image] {
            guard let validImage = mustBeNSImageIfPresent as? NSImage else {
                return nil
            }
            image = validImage
        }

        guard let cutDicts = dictionary[Keys.Cuts] as? [[String: AnyObject]] else {
            return nil
        }
        let cuts = cutDicts.compactMap { Cut(dictionary: $0) }
        guard cuts.count == cutDicts.count else {
            return nil
        }


        guard let selectionDicts = dictionary[Keys.Selections] as? [[String: AnyObject]] else {
            return nil
        }
        let selections = selectionDicts.compactMap { Mark(dictionary: $0) }
        guard selections.count == selectionDicts.count else {
            return nil
        }

        self.init(image: image, cuts: cuts, selections: selections)
        self.imageFrom = from
    }
}
