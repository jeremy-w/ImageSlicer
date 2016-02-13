import Cocoa

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
