//  Copyright © 2016 Jeremy W. Sherman. Released with NO WARRANTY.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Cocoa

class RenameViewController: NSViewController {
    private var completion = {(_: String) -> Void in return}
    private var originalName = "" {
        didSet {
            nameDidChange()
        }
    }

    func configure(name: String, completion: @escaping (String) -> Void) {
        originalName = name
        self.completion = completion
    }

    @IBOutlet var nameField: NSTextField!

    @objc(okAction:)
    @IBAction func okAction(sender: AnyObject) {
        dismiss(self)
        completion(nameField.stringValue)
    }

    @objc(cancelAction:)
    @IBAction func cancelAction(sender: AnyObject) {
        dismiss(self)
        completion(originalName)
    }

    func nameDidChange() {
        nameField?.stringValue = originalName
    }
}


extension RenameViewController {
    override func viewDidLoad() {
        nameDidChange()
    }
}
