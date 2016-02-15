import Cocoa

class Job {
    var image: NSImage?
    var cuts: [Cut]
    var selections: [ExportSelection]

    init(image: NSImage?, cuts: [Cut] = [], selections: [ExportSelection] = []) {
        self.image = image
        self.cuts = cuts
        self.selections = selections
    }

    func add(cut: Cut) {
        cuts.append(cut)
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
            subimages.replaceRange(Range(start: index, end: index + 1), with: children)
        }

        return subimages
    }

    func rename(mark: ExportSelection, to name: String) {
        guard let index = selections.indexOf(mark) else { return }
        let oldMark = selections[index]
        let renamedMark = ExportSelection(around: oldMark.around, name: name)
        selections.replaceRange(Range(start: index, end: index + 1), with: [renamedMark])
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
        NSLog("\(__FUNCTION__): pickled \(self): \(dictionary)")
        return dictionary
    }

    convenience init?(dictionary: [String: AnyObject]) {
        NSLog("\(__FUNCTION__): unpickling: \(dictionary)")
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
        let selections = selectionDicts.flatMap { ExportSelection(dictionary: $0) }
        guard selections.count == selectionDicts.count else {
            return nil
        }

        self.init(image: actualImage, cuts: cuts, selections: selections)
    }
}
