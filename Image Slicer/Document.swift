//
//  Document.swift
//  Image Slicer
//
//  Created by Jeremy on 2016-02-13.
//  Copyright © 2016 Jeremy W. Sherman. Released with NO WARRANTY.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Cocoa

class Document: NSDocument {
    static let nativeType = "com.jeremywsherman.slicedimage"

    var job = Job(image: nil) {
        didSet {
            updateViewControllerJob()
        }
    }

    override class var autosavesInPlace: Bool {
        return true
    }

    override func makeWindowControllers() {
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "Document Window Controller")) as! NSWindowController
        self.addWindowController(windowController)

        updateViewControllerJob()
    }

    func updateViewControllerJob() {
        if let
            windowController = self.windowControllers.first,
            let vc = windowController.contentViewController as? JobViewController {
                vc.job = self.job
        }
    }

    override static func canConcurrentlyReadDocuments(ofType typeName: String) -> Bool {
        return typeName == nativeType
    }

    override func data(ofType typeName: String) throws -> Data {
        let dict = job.asDictionary
        let data = NSKeyedArchiver.archivedData(withRootObject: dict)
        return data
    }

    override func read(from data: Data, ofType typeName: String) throws {
        guard let something = NSKeyedUnarchiver.unarchiveObject(with: data) else {
            throw NSError(domain: "blargh", code: 1, userInfo:  [
                NSLocalizedDescriptionKey: "Failed to unarchive data",
                ])
        }

        guard let dict = something as? [String: AnyObject] else {
            throw NSError(domain: "blargh", code: 1, userInfo:  [
                NSLocalizedDescriptionKey: "Unarchived thing wasn't a dictionary",
                NSLocalizedFailureReasonErrorKey: "Was: \(something)",
                ])
        }

        guard let job = Job(dictionary: dict) else {
            throw NSError(domain: "blargh", code: 1, userInfo:  [
                NSLocalizedDescriptionKey: "Job unpickling failed",
                ])
        }

        self.job = job
    }


    override func defaultDraftName() -> String {
        return NSLocalizedString("Sliced Image", comment: "default draft document name")
    }


    /// Invoked by `JobView` when a file gets dropped on it.
    ///
    /// Originally was an `@IBAction`, but the responder chain didn't
    /// seem to find it, so forget that.
    func renameDraft() {
        guard notYetSaved else { return }

        adoptNameFromImageURL()
    }


    /// Per docs, `draft` should be equivalent to `fileURL == nil`,
    /// but it appears that autosave has broken that equivalence,
    /// so that the document never presents as `draft` any more.
    var notYetSaved: Bool {
        return fileURL == nil
    }


    func adoptNameFromImageURL() {
        guard let imageURL = job.imageFrom else { return }

        displayName = imageURL.deletingPathExtension().lastPathComponent
        // You'd think that would automatically update the name shown by the window, but, nope.
        windowControllers.forEach {
            $0.synchronizeWindowTitleWithDocumentName()
        }
    }


    override func prepareSavePanel(_ savePanel: NSSavePanel) -> Bool {
        aimAtSourceImageURLIfDraft(savePanel: savePanel)
        return true
    }


    func aimAtSourceImageURLIfDraft(savePanel: NSSavePanel) {
        guard notYetSaved else { return }
        guard let directoryURL = job.imageFrom?.deletingLastPathComponent() else { return }
        savePanel.directoryURL = directoryURL
    }
}

