// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Cocoa

class JobViewController: NSViewController {
    @IBOutlet var jobView: JobView!
    var notificationCenter = NSNotificationCenter.defaultCenter()

    override func viewDidLoad() {
        super.viewDidLoad()
        jobView.editMark = { [weak self] mark, rect, completion in
            guard let me = self else {
                completion(false)
                return
            }

            me.editName(mark, rect: rect, of: me.jobView, completion: completion)
        }

        configureJob()
    }


    var job: Job? {
        didSet {
            configureJob()
        }
    }

    private func configureJob() {
        guard let job = self.job else { return }

        let undoManager = jobView.window?.undoManager
        job.undoing = undoManager
        jobView.job = job

        undoManagerDidChange(undoManager)
    }


    var document: Document? {
        guard viewLoaded else { return nil }

        let document = view.window?.windowController?.document as? Document
        return document
    }
}


// MARK: - Refresh on Undo/Redo
extension JobViewController {
    /// Unsubscribes from undo/redo notifications then,
    /// if `undoManager` non-nil, subscribes to its notifications.
    ///
    /// Notification management is done through `notificationCenter`.
    func undoManagerDidChange(undoManager: NSUndoManager?) {
        let names = [NSUndoManagerDidUndoChangeNotification, NSUndoManagerDidRedoChangeNotification]
        for name in names {
            notificationCenter.removeObserver(self, name: name, object: nil)
        }

        guard let undoManager = undoManager else { return }
        for name in names {
            notificationCenter.addObserver(self, selector: Selector("markViewDirtyFollowingUndoOrRedo:"), name: name, object: undoManager)
        }
    }


    /// Called as a result of an undo manager did undo/redo change notification.
    func markViewDirtyFollowingUndoOrRedo(note: NSNotification) {
        guard viewLoaded else { return }

        view.needsDisplay = true
    }
}



// MARK: - Cut Management
extension JobViewController {
    @IBAction func addCutHorizontalAction(sender: NSButton) {
        jobView.editingMode = .AddingCut(.Horizontally)
    }


    @IBAction func addCutVerticalAction(sender: NSButton) {
        jobView.editingMode = .AddingCut(.Vertically)
    }


    @IBAction func deleteCutAction(sender: NSButton) {
        jobView.editingMode = .DeletingCut
    }

    @IBAction func deleteAllCutsAndMarksAction(sender: AnyObject) {
        guard let job = self.job else {
            return
        }

        job.cuts = []
        job.selections = []
        jobView.needsDisplay = true
    }
}



// MARK: - Mark Management
extension JobViewController {
    @IBAction func markSliceForExportAction(sender: AnyObject) {
        jobView.editingMode = .AddingMark
    }

    @IBAction func deleteMarkAction(sender: AnyObject) {
        jobView.editingMode = .DeletingMark
    }

    @IBAction func deleteAllMarksAction(sender: AnyObject) {
        guard let job = self.job else {
            return
        }

        job.selections = []
        jobView.needsDisplay = true
    }
}



// MARK: - Export
extension JobViewController {
    @IBAction func exportMarkedSlicesAction(sender: AnyObject) {
        guard let window = view.window else {
            NSLog("%@", "\(#function): \(self): we have no window!")
            NSBeep()
            return
        }

        let directoryPicker = self.dynamicType.exportDirectoryPicker()
        if let document = self.document,
            directoryURL = document.fileURL?.URLByDeletingLastPathComponent {
                directoryPicker.directoryURL = directoryURL
        }

        directoryPicker.beginSheetModalForWindow(window) { response in
            guard response == NSFileHandlingPanelOKButton else {
                NSLog("%@", "user canceled export")
                return
            }

            guard let directory = directoryPicker.URL else {
                NSLog("%@", "user failed to select directory")
                return
            }

            NSLog("%@", "exporting to: \(directory.lastPathComponent) at \(directory.absoluteURL)")
            let _ = self.job?.exportSelectedSubimages(directory, dryRun: false)
        }
    }


    func presentErrorPreferringModal(error: ErrorType) {
        let nserror = error as NSError
        guard viewLoaded, let window = self.view.window else {
            presentError(nserror)
            return
        }

        presentError(nserror, modalForWindow: window, delegate: nil, didPresentSelector: nil, contextInfo: nil)
    }


    static func exportDirectoryPicker() -> NSOpenPanel {
        let directoryPicker = NSOpenPanel()
        directoryPicker.canChooseDirectories = true
        directoryPicker.canCreateDirectories = true
        directoryPicker.canChooseFiles = false
        directoryPicker.allowsMultipleSelection = false

        directoryPicker.title = NSLocalizedString("Choose Export Directory", comment: "export panel title")
        directoryPicker.prompt = NSLocalizedString("Choose", comment: "export panel prompt")
        directoryPicker.nameFieldLabel = NSLocalizedString("Export to:", comment: "export panel name field label")
        directoryPicker.message = NSLocalizedString("All marked slices will be exported as PNG images in the chosen directory.", comment: "export panel message")

        return directoryPicker
    }
}


extension JobViewController {
    func editName(
        mark: Mark,
        rect: CGRect,
        of view: NSView,
        completion: (Bool) -> Void
    ) {
        NSLog("%@", "\(#function): \(mark)")
        guard let renamer = storyboard?.instantiateControllerWithIdentifier("renamer") as?RenameViewController else {
            fatalError("failed to instantiate renamer")
        }

        renamer.configure(mark.name) { [weak self] name in
            guard name != mark.name, let me = self else {
                completion(false)
                return
            }

            NSLog("%@", "\(#function): \(self): renaming \(mark) to \"\(name)\"")
            me.job?.rename(mark, to: name)
            completion(true)
        }
        presentViewController(renamer, asPopoverRelativeToRect: rect, ofView: view, preferredEdge: .MinY, behavior: .Semitransient)
    }
}
