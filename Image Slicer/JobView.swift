import Cocoa

enum EditingMode {
    case NotEditing
    case AddingCut(Orientation)
    case AddingMark
    case DeletingCut
    case DeletingMark
}

let markTextColor = NSColor.blueColor()
let highlightColor = NSColor.orangeColor().colorWithAlphaComponent(0.4)
let highlightedMarkAttributes = [NSForegroundColorAttributeName: markTextColor
    , NSBackgroundColorAttributeName: highlightColor]

class JobView: NSImageView {
    var job = Job(image: nil, cuts: [], selections: []) {
        didSet {
            image = job.image
        }
    }

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


    /// - returns: true if mark name changed (invalidates rect), false otherwise
    var editMark: (ExportSelection, rect: CGRect, completion: (Bool) -> Void) -> Void =
        { _, _, completion in
            NSLog("default mark handler does nothing")
            completion(false)
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

    var mouseAt: CGPoint? = nil {
        didSet {
            let wasAt = oldValue

            if case .DeletingCut = editingMode {
                let oldCut = wasAt.flatMap { cutNearest($0)?.0 }
                let newCut = mouseAt.flatMap { cutNearest($0)?.0 }

                if let oldCut = oldCut {
                    setNeedsDisplayInRect(rectFor(oldCut))
                }

                if let newCut = newCut {
                    setNeedsDisplayInRect(rectFor(newCut))
                }
            }

            // TODO: update highlighted marks
//            let oldMark = wasAt.flatMap { markNearest($0)?.0 }
//            let newMark = mouseAt.flatMap { markNearest($0)?.0 }
        }
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

        labelSelections(markTextColor)
    }


    func outlineSubimages() {
        for sub in job.subimages {
            NSFrameRect(sub.rect)
        }
    }


    func markCutPoints() {
        let victimCut = mouseAt.flatMap { point -> Cut? in
            guard case .DeletingCut = editingMode else { return nil }
            return cutNearest(point)?.0
        }

        for cut in job.cuts {
            let rect = rectFor(cut)
            let isVictim = victimCut.map { $0 == cut } ?? false
            if isVictim {
                NSGraphicsContext.currentContext()?.saveGraphicsState()
                NSColor.orangeColor().setFill()
            }

            NSRectFill(CGRectOffset(rect, -1, -1))

            if isVictim {
                NSGraphicsContext.currentContext()?.restoreGraphicsState()
            }
        }
    }


    func rectFor(cut: Cut) -> CGRect {
        return CGRect(origin: cut.at, size: CGSize(width: 2, height: 2))
    }


    override func mouseMoved(theEvent: NSEvent) {
        let windowPoint = theEvent.locationInWindow
        mouseAt = self.convertPoint(windowPoint, fromView: nil)
    }


    var highlightedSelection: ExportSelection? {
        get {
            let highlightedSelection = mouseAt.flatMap { markNearest($0)?.0 }
            return highlightedSelection
        }
    }


    func labelSelections(textColor: NSColor) {
        let normalAttributes = [NSForegroundColorAttributeName: textColor]
        let highlightedAttributes = highlightedMarkAttributes
        let highlighted = highlightedSelection
        for selection in job.selections {
            let shouldHighlight = highlighted.map { $0 == selection } ?? false
            let attributes = shouldHighlight ? highlightedAttributes : normalAttributes
            let rect = rectFor(selection, attributes: attributes)
            selection.name.drawInRect(rect, withAttributes: attributes)
        }
    }


    func rectFor(mark: ExportSelection, attributes: [String: AnyObject]) -> CGRect {
        let text = mark.name
        let size = text.sizeWithAttributes(attributes)
        let pointCenteringTextOnMark = CGPoint(
            x: mark.around.x - size.width / 2,
            y: mark.around.y - size.height / 2)
        let rect = CGRect(origin: pointCenteringTextOnMark, size: size)
        return rect
    }
}



// MARK: - Editing
extension JobView {
    override func mouseDown(theEvent: NSEvent) {
        let windowPoint = theEvent.locationInWindow
        let point = convertPoint(windowPoint, fromView: nil)
        mouseAt = point

        if let mode = performEdit(point) {
            editingMode = mode
            needsDisplay = true
        }
    }


    func editHighlightedMark(mark: ExportSelection) {
        let rect = rectFor(mark, attributes: highlightedMarkAttributes)
        editMark(mark, rect: rect) { didRename in
            guard didRename else { return }
            self.needsDisplay = true
        }
    }


    /// - returns: next mode to change to, if any
    func performEdit(point: CGPoint) -> EditingMode? {
        switch editingMode {
        case .NotEditing:
            if let mark = highlightedSelection {
                let rect = rectFor(mark, attributes: highlightedMarkAttributes)
                if CGRectContainsPoint(rect, point) {
                    editHighlightedMark(mark)
                }
            }
            return nil

        case let .AddingCut(orientation):
            job.add(Cut(at: point, oriented: orientation))
            return .NotEditing

        case .AddingMark:
            let name = "mark \(job.selections.count + 1)"
            let mark = ExportSelection(around: point, name: name)
            job.selections.append(mark)
            editHighlightedMark(mark)
            return .NotEditing

        case .DeletingCut:
            if let (_, index) = cutNearest(point) {
                    job.cuts.removeAtIndex(index)
                    return .NotEditing
            }

        case .DeletingMark:
            if let (_, index) = markNearest(point) {
                    job.selections.removeAtIndex(index)
                    return .NotEditing
            }
        }

        fatalError("somehow made it past an exhaustive switch-case with editingMode: \(editingMode)")
    }


    func cutNearest(point: CGPoint) -> (Cut, Int)? {
        if let hitPoint = nearest(point, amongst: job.cuts.map { $0.at }),
            index = job.cuts.indexOf({ $0.at == hitPoint }) {
                return (job.cuts[index], index)
        }
        return nil
    }


    func markNearest(point: CGPoint) -> (ExportSelection, Int)? {
        if let hitPoint = nearest(point, amongst: job.selections.map { $0.around }),
            index = job.selections.indexOf({ $0.around == hitPoint }) {
                return (job.selections[index], index)
        }
        return nil
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
