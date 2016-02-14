import Cocoa

enum EditingMode {
    case NotEditing
    case AddingCut(Orientation)
    case AddingMark
    case DeletingCut
    case DeletingMark
}

class JobView: NSImageView {
    var job = Job(image: nil, cuts: [], selections: [])

    var editingMode = EditingMode.NotEditing {
        didSet {
            guard self.editable else {
                NSLog("\(__FUNCTION__): \(self): not editable, so refusing change to mode \(editingMode)")
                editingMode = .NotEditing
                return
            }

            NSLog("\(__FUNCTION__): \(self): \(editingMode)")
            if case .NotEditing = editingMode {
                didFinishEditing(self)
            }
        }
    }

    var didFinishEditing: (JobView) -> Void = { _ in
        NSLog("\(__FUNCTION__)")
    }

    override var image: NSImage? {
        get {
            return super.image
        }

        set {
            guard image == nil else {
                return
            }

            super.image = newValue
            imageDidChange(image)
        }
    }


    func imageDidChange(image: NSImage?) {
        NSLog("\(__FUNCTION__): \(image)")
        self.job.image = image
        invalidateIntrinsicContentSize()
    }


    override var intrinsicContentSize: NSSize {
        get {
            return image.map({ $0.size }) ?? super.intrinsicContentSize
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



// MARK: - Editing
extension JobView {
    override func mouseDown(theEvent: NSEvent) {
        let windowPoint = theEvent.locationInWindow
        let point = convertPoint(windowPoint, fromView: nil)

        if let mode = performEdit(point) {
            editingMode = mode
            needsDisplay = true
        }
    }


    /// - returns: next mode to change to, if any
    func performEdit(point: CGPoint) -> EditingMode? {
        switch editingMode {
        case .NotEditing:
            return nil

        case let .AddingCut(orientation):
            job.add(Cut(at: point, oriented: orientation))
            return .NotEditing

        case .AddingMark:
            let name = "Subimage \(job.selections.count + 1)"
            job.selections.append(ExportSelection(around: point, name: name))
            return .NotEditing

        case .DeletingCut:
            if let hitPoint = nearest(point, amongst: job.cuts.map { $0.at }),
                index = job.cuts.indexOf({ $0.at == hitPoint }) {
                    job.cuts.removeAtIndex(index)
                    return .NotEditing
            }

        case .DeletingMark:
            if let hitPoint = nearest(point, amongst: job.selections.map { $0.around }),
                index = job.selections.indexOf({ $0.around == hitPoint }) {
                    job.selections.removeAtIndex(index)
                    return .NotEditing
            }
        }

        fatalError("somehow made it past an exhaustive switch-case with editingMode: \(editingMode)")
    }


    /// - returns: optional since `points` might be empty
    func nearest(target: CGPoint, amongst points: [CGPoint]) -> CGPoint? {
        let pointsAndDistances = points.map { point -> (CGPoint, CGFloat) in
            let dx = point.x - target.x
            let dy = point.y - target.y
            return (point, dx*dx + dy*dy)
        }
        let pointAndMinDistance = pointsAndDistances.minElement { (left, right) -> Bool in
            return left.1 < right.1
        }
        return pointAndMinDistance?.0
    }
}
