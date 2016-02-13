import Cocoa

class JobView: NSImageView {
    var job = Job(image: nil, cuts: [], selections: [])

    override var image: NSImage? {
        didSet {
            self.job.image = image
        }
    }

    init?(job: Job) {
        self.job = job

        guard let image = job.image else {
            super.init(frame: CGRectZero)
            return nil
        }

        let frame = CGRect(origin: CGPointZero, size: image.size)
        super.init(frame: frame)
        self.image = image
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}


// MARK: - Drawing
extension JobView {
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

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
