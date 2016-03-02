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

    override class func autosavesInPlace() -> Bool {
        return true
    }

    override func makeWindowControllers() {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let windowController = storyboard.instantiateControllerWithIdentifier("Document Window Controller") as! NSWindowController
        self.addWindowController(windowController)

        updateViewControllerJob()
    }

    func updateViewControllerJob() {
        if let
            windowController = self.windowControllers.first,
            vc = windowController.contentViewController as? JobViewController {
                vc.job = self.job
        }
    }

    override static func canConcurrentlyReadDocumentsOfType(typeName: String) -> Bool {
        return typeName == nativeType
    }

    override func dataOfType(typeName: String) throws -> NSData {
        let dict = job.asDictionary
        let data = NSKeyedArchiver.archivedDataWithRootObject(dict)
        return data
    }

    override func readFromData(data: NSData, ofType typeName: String) throws {
        guard let something = NSKeyedUnarchiver.unarchiveObjectWithData(data) else {
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


//    override func restoreDocumentWindowWithIdentifier(identifier: String, state: NSCoder, completionHandler: (NSWindow?, NSError?) -> Void) {
//        NSLog("DEBUG: state restoration disabled")
//        completionHandler(nil, nil)
//    }

}

