//
//  ViewController.swift
//  Image Slicer
//
//  Created by Jeremy on 2016-02-13.
//  Copyright © 2016 Jeremy W. Sherman. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet var jobView: JobView!

    override func viewDidLoad() {
        super.viewDidLoad()
        jobView.editMark = { [weak self] mark, rect, completion in
            guard let me = self else {
                completion(false)
                return
            }

            me.editName(mark, rect: rect, of: me.jobView, completion: completion)
        }

        if let job = job {
            jobView.job = job
        }
    }

    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    var job: Job? {
        didSet {
            if let job = job {
                jobView.job = job
            }
        }
    }
}



// MARK: - Cut Management
extension ViewController {
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
extension ViewController {
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
extension ViewController {
    @IBAction func exportMarkedSlicesAction(sender: AnyObject) {
        guard let window = view.window else {
            NSLog("\(__FUNCTION__): \(self): we have no window!")
            NSBeep()
            return
        }

        let directoryPicker = self.dynamicType.exportDirectoryPicker()
        if let document = view.window?.windowController?.document as? Document,
            directoryURL = document.fileURL?.URLByDeletingLastPathComponent {
                directoryPicker.directoryURL = directoryURL
        }

        directoryPicker.beginSheetModalForWindow(window) { response in
            guard response == NSFileHandlingPanelOKButton else {
                NSLog("user canceled export")
                return
            }

            guard let url = directoryPicker.URL else {
                NSLog("user failed to select directory")
                return
            }

            NSLog("exporting to: \(url.lastPathComponent) at \(url.absoluteURL)")
            self.job?.exportSelectedSubimages(url, dryRun: false)
        }
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


extension ViewController {
    func editName(
        mark: ExportSelection,
        rect: CGRect,
        of view: NSView,
        completion: (Bool) -> Void
    ) {
        NSLog("\(__FUNCTION__): \(mark)")
        guard let renamer = storyboard?.instantiateControllerWithIdentifier("renamer") as?RenameViewController else {
            fatalError("failed to instantiate renamer")
        }

        renamer.configure(mark.name) { [weak self] name in
            guard name != mark.name, let me = self else {
                completion(false)
                return
            }

            NSLog("\(__FUNCTION__): \(self): renaming \(mark) to \"\(name)\"")
            me.job?.rename(mark, to: name)
            completion(true)
        }
        presentViewController(renamer, asPopoverRelativeToRect: rect, ofView: view, preferredEdge: .MinY, behavior: .Semitransient)
    }
}
