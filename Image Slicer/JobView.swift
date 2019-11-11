//  Copyright © 2016 Jeremy W. Sherman. Released with NO WARRANTY.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Cocoa

enum EditingMode {
    case NotEditing
    case AddingCut(Orientation)
    case AddingMark
    case DeletingCut
    case DeletingMark
}

let markTextColor = NSColor.blue
let highlightColor = NSColor.orange.withAlphaComponent(0.4)
let highlightedMarkAttributes: [NSAttributedString.Key: Any] = [
    .foregroundColor: markTextColor,
    .backgroundColor: highlightColor,
]

class JobView: NSImageView {
    var job = Job(image: nil, cuts: [], selections: []) {
        didSet {
            image = job.image
        }
    }

    var editingMode = EditingMode.NotEditing {
        didSet {
            guard self.isEditable else {
                NSLog("%@", "\(#function): \(self): not editable, so refusing change to mode \(editingMode)")
                editingMode = .NotEditing
                return
            }

            NSLog("%@", "\(#function): \(self): \(editingMode)")
            editingModeDidChange(self)
        }
    }

    var editingModeDidChange: (JobView) -> Void = { jobView in
        NSLog("%@: editingModeDidChange", jobView)
    }


    /// - returns: true if mark name changed (invalidates rect), false otherwise
    var editMark: (Mark, _ rect: CGRect, _ completion: @escaping (Bool) -> Void) -> Void =
        { _, _, completion in
            NSLog("%@", "default mark handler does nothing")
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
            imageDidChange(image: image)
        }
    }


    func imageDidChange(image: NSImage?) {
        NSLog("%@", "\(#function): \(String(describing: image))")
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
            super.init(frame: .zero)
            return nil
        }

        let frame = CGRect(origin: .zero, size: image.size)
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
                let oldCut = wasAt.flatMap { cutNearest(point: $0)?.0 }
                let newCut = mouseAt.flatMap { cutNearest(point: $0)?.0 }

                if let oldCut = oldCut {
                    setNeedsDisplay(rectFor(cut: oldCut))
                }

                if let newCut = newCut {
                    setNeedsDisplay(rectFor(cut: newCut))
                }
            }

            // TODO: update highlighted marks
//            let oldMark = wasAt.flatMap { markNearest($0)?.0 }
//            let newMark = mouseAt.flatMap { markNearest($0)?.0 }
        }
    }
}



// MARK: - Drag & Drop
extension JobView {
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let didAcceptDrag = super.performDragOperation(sender)
        guard didAcceptDrag else {
            return didAcceptDrag
        }

        let pasteboard = sender.draggingPasteboard
        let fileURL = firstFileURL(from: pasteboard)
        NSLog("%@", "dropped file URL was: \(String(describing: fileURL))")

        self.job.imageFrom = fileURL

        // Tried pitching this up the responder chain, but oddly, it wasn't handled.
        // So let's get handsy.
        if let document = self.window?.windowController?.document as? Document {
            document.renameDraft()
        }
        return didAcceptDrag
    }


    func firstFileURL(from pasteboard: NSPasteboard) -> URL? {
        guard let URLs = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [NSURL] else {
                return nil
        }

        let fileURL = URLs.first?.filePathURL
        return fileURL
    }
}



// MARK: - Drawing
extension JobView {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.green.set()
        outlineSubimages()

        NSColor.red.set()
        markCutPoints()

        labelSelections(textColor: markTextColor)
    }


    func outlineSubimages() {
        for sub in job.subimages {
            sub.rect.frame(withWidth: 1.0, using: .copy)
        }
    }


    func markCutPoints() {
        let victimCut = mouseAt.flatMap { point -> Cut? in
            guard case .DeletingCut = editingMode else { return nil }
            return cutNearest(point: point)?.0
        }

        for cut in job.cuts {
            let rect = rectFor(cut: cut)
            let isVictim = victimCut.map { $0 == cut } ?? false
            if isVictim {
                NSGraphicsContext.current?.saveGraphicsState()
                NSColor.orange.setFill()
            }

            rect.offsetBy(dx: -1, dy:-1).fill()

            if isVictim {
                NSGraphicsContext.current?.restoreGraphicsState()
            }
        }
    }


    func rectFor(cut: Cut) -> CGRect {
        return CGRect(origin: cut.at, size: CGSize(width: 2, height: 2))
    }


    override func mouseMoved(with theEvent: NSEvent) {
        let windowPoint = theEvent.locationInWindow
        mouseAt = self.convert(windowPoint, from: nil)
    }


    var highlightedSelection: Mark? {
        get {
            let highlightedSelection = mouseAt.flatMap { markNearest(point: $0)?.0 }
            return highlightedSelection
        }
    }


    func labelSelections(textColor: NSColor) {
        let normalAttributes = [NSAttributedString.Key.foregroundColor: textColor]
        let highlightedAttributes = highlightedMarkAttributes
        let highlighted = highlightedSelection
        for selection in job.selections {
            let shouldHighlight = highlighted.map { $0 == selection } ?? false
            let attributes = shouldHighlight ? highlightedAttributes : normalAttributes
            let rect = rectFor(mark: selection, attributes: attributes)
            selection.name.draw(in: rect, withAttributes: attributes)
        }
    }


    func rectFor(mark: Mark, attributes: [NSAttributedString.Key: Any]) -> CGRect {
        let text = mark.name
        let size = text.size(withAttributes: attributes)
        let pointCenteringTextOnMark = CGPoint(
            x: mark.around.x - size.width / 2,
            y: mark.around.y - size.height / 2)
        let rect = CGRect(origin: pointCenteringTextOnMark, size: size)
        return rect
    }
}



// MARK: - Editing
extension JobView {
    override func mouseDown(with theEvent: NSEvent) {
        let windowPoint = theEvent.locationInWindow
        let point = convert(windowPoint, from: nil)
        mouseAt = point

        // Previously, we relied on job.didSet triggering whenever job was mutated.
        // Newer Swift does not behave that way, though.
        let willNeedDisplay = editingMode.needsDisplayAfterAction
        if let mode = performEdit(point: point) {
            editingMode = mode
            needsDisplay = true
        }
        needsDisplay = needsDisplay || willNeedDisplay
    }


    func editHighlightedMark(mark: Mark) {
        let rect = rectFor(mark: mark, attributes: highlightedMarkAttributes)
        editMark(mark, rect) { didRename in
            guard didRename else { return }
            self.needsDisplay = true
        }
    }


    /// - returns: next mode to change to, if any
    func performEdit(point: CGPoint) -> EditingMode? {
        switch editingMode {
        case .NotEditing:
            if let mark = highlightedSelection {
                let rect = rectFor(mark: mark, attributes: highlightedMarkAttributes)
                if rect.contains(point) {
                    editHighlightedMark(mark: mark)
                }
            }
            return nil

        case let .AddingCut(orientation):
            // Place cuts at integral locations so that the resulting sliced-up image
            // doesn't end up blurry due to smooshing a pixel across a few neighbors.
            let integralPoint = CGPoint(
                x: round(point.x),
                y: round(point.y))
            job.add(cut: Cut(at: integralPoint, oriented: orientation))
            return nil

        case .AddingMark:
            let name = "mark \(job.selections.count + 1)"
            let mark = Mark(around: point, name: name)
            job.add(mark: mark)
            editHighlightedMark(mark: mark)
            return nil

        case .DeletingCut:
            if let (cut, _) = cutNearest(point: point) {
                job.remove(cut: cut)
            }
            return .NotEditing

        case .DeletingMark:
            if let (mark, _) = markNearest(point: point) {
                job.remove(mark: mark)
            }
            return .NotEditing
        }
    }


    func cutNearest(point: CGPoint) -> (Cut, Int)? {
        if let hitPoint = nearest(target: point, amongst: job.cuts.map { $0.at }),
            let index = job.cuts.firstIndex(where: { $0.at == hitPoint }) {
                return (job.cuts[index], index)
        }
        return nil
    }


    func markNearest(point: CGPoint) -> (Mark, Int)? {
        if let hitPoint = nearest(target: point, amongst: job.selections.map { $0.around }),
            let index = job.selections.firstIndex(where: { $0.around == hitPoint }) {
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
        let pointAndMinDistance = pointsAndDistances.min { (left, right) -> Bool in
            return left.1 < right.1
        }
        return pointAndMinDistance?.0
    }
}

private extension EditingMode {
    /**
     Helps `mouseDown(with:)` decide whether to redisplay after processing the action.
     */
    var needsDisplayAfterAction: Bool {
        switch self {
        case .NotEditing:
            return false

        case .AddingCut(_):
            return true

        case .AddingMark:
            return true

        case .DeletingCut:
            return true

        case .DeletingMark:
            return true
        }
    }
}
