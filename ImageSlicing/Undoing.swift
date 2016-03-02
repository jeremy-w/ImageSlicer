//  Copyright © 2016 Jeremy W. Sherman. Released with NO WARRANTY.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

protocol Undoing {
    func record(actionName: String, undo: () -> Void)
}


extension NSUndoManager: Undoing {
    func record(actionName: String, undo: () -> Void) {
        let closure = PerformableClosure(undo)
        self.registerUndoWithTarget(PerformableClosure.self, selector: Selector("perform:"), object: closure)
        if !self.undoing && !self.redoing {
            self.setActionName(actionName)
        }
    }
}


/// Added to provide undo support.
class PerformableClosure: NSObject {
    let closure: () -> Void
    init(_ closure: () -> Void) {
        self.closure = closure
    }

    @objc
    func perform() {
        closure()
    }

    @objc
    class func perform(closure: PerformableClosure) {
        closure.perform()
    }
}
