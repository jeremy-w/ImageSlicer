// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Cocoa


/// Translates `JobView.editingMode` changes into `statusField.stringValue`.
class EditingModeReporter: NSObject {
    /// Describes the effect a click on `jobView` will have.
    ///
    /// Updated on `jobView.editingModeDidChange`.
    @IBOutlet var statusField: NSTextField!


    /// The `jobView` whose status should be watched.
    @IBOutlet var jobView: JobView! {
        didSet {
            configureJobView()
        }
    }


    func configureJobView() {
        jobView.editingModeDidChange = { [weak self] _ in
            self?.updateStatusFieldStringValue()
        }
    }


    func updateStatusFieldStringValue() {
        guard let
            statusField = self.statusField
        else {
            NSLog("%@", "\(#function): statusField outlet is not connected")
            return
        }

        statusField.stringValue = type(of: self).status(for: jobView.editingMode)
    }


    /// Returns a description of what the next click on a `JobView` in `mode` will do.
    static func status(`for` mode: EditingMode) -> String {
        switch mode {
        case .NotEditing:
            return ""

        case let .AddingCut(orientation):
            switch (orientation) {
            case .Horizontally:
                return NSLocalizedString("Click the image to add a horizontal cut", comment: "status label text")

            case .Vertically:
                return NSLocalizedString("Click the image to add a vertical cut", comment: "status label text")
            }

        case .AddingMark:
            return NSLocalizedString("Click the image to mark a slice for export", comment: "status label text")

        case .DeletingCut:
            return NSLocalizedString("Click the image to delete the nearest cut", comment: "status label text")

        case .DeletingMark:
            return NSLocalizedString("Click the image to delete the nearest mark", comment: "status label text")
        }
    }

}
