// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
@testable import Image_Slicer

class UndoingTests: XCTestCase {
    var job = Job(image: nil)
    let undo = UndoingSpy()

    let anyCut = Cut(at: .zero, oriented: .Horizontally)
    let anyMark = Mark(around: .zero, name: "any mark")

    override func setUp() {
        job.undoing = undo
    }

    func testAddingCutCanBeUndone() {
        job.add(cut: anyCut)
        undo.undo()
        XCTAssertEqual(job.cuts, [])
    }

    func testAddingMarkCanBeUndone() {
        job.add(mark: anyMark)
        undo.undo()
        XCTAssertEqual(job.selections, [])
    }

    func testUndoingAddCutCanBeRedone() {
        job.add(cut: anyCut)
        undo.undo()
        undo.redo()
        XCTAssertEqual(job.cuts, [anyCut])
    }

    func testRemovingCutFromMiddleOfCutsListCanBeUndone() {
        job.add(cut: anyCut)
        let secondCut = Cut(at: CGPoint(x: 1, y: 1), oriented: .Vertically)
        job.add(cut: secondCut)
        let thirdCut = Cut(at: CGPoint(x: 2, y: 2), oriented: .Horizontally)
        job.add(cut: thirdCut)

        job.remove(cut: secondCut)
        undo.undo()
        XCTAssertEqual(job.cuts, [anyCut, secondCut, thirdCut])
    }

    func testRepeatedUndoRedoAddMarkHasNoEffect() {
        job.add(mark: anyMark)
        let before = job.selections
        (0..<10).forEach { _ in
            undo.undo()
            undo.redo()
        }
        let after = job.selections
        XCTAssertEqual(after, before)
    }

    func testRenamingMarkCanBeUndoneAndRedone() {
        job.add(mark: anyMark)
        job.rename(mark: anyMark, to: "renamed mark")
        let renamedMark = job.selections.last!
        XCTAssertEqual(job.selections, [renamedMark])

        undo.undo()
        XCTAssertEqual(job.selections, [anyMark])

        undo.redo()
        XCTAssertEqual(job.selections, [renamedMark])
    }
}


class UndoingSpy: Undoing {
    var undoStack: [() -> Void] = []
    var redoStack: [() -> Void] = []
    var undoing = false

    func record(actionName: String, undo: @escaping () -> Void) {
        if undoing {
            redoStack.append(undo)
        } else {
            undoStack.append(undo)
        }
    }

    func undo() {
        let last = undoStack.removeLast()
        undoing = true
        NSLog("%@", "[[[ UNDO ---")
        last()
        NSLog("%@", "--- UNDO ]]]")
        undoing = false
    }

    func redo() {
        let last = redoStack.removeLast()
        NSLog("%@", "[[[ REDO ---")
        last()
        NSLog("%@", "--- REDO ]]]")
    }
}
