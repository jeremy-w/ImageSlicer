//
//  AppDelegate.swift
//  Image Slicer
//
//  Created by Jeremy on 2016-02-13.
//  Copyright © 2016 Jeremy W. Sherman. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func application(sender: NSApplication, openFiles filenames: [String]) {
        NSLog("asked to open files: \(filenames.joinWithSeparator("\n- "))")
        for file in filenames {
            guard openFile(file) else {
                NSApp.replyToOpenOrPrint(.Failure)
                return
            }
        }
        NSApp.replyToOpenOrPrint(.Success)
    }

    func openFile(file: String) -> Bool {
        let controller = NSDocumentController.sharedDocumentController()

        let URL = NSURL(fileURLWithPath: file)
        if let image = NSImage(contentsOfURL: URL) {
            do {
                let someDocument = try controller.makeUntitledDocumentOfType(Document.nativeType)
                guard let myDocument = someDocument as? Document else {
                    NSLog("\(someDocument) has wrong class: opened \(file)")
                    return false
                }

                controller.addDocument(someDocument)

                myDocument.job = Job(image: image)
                if let imageName = URL.URLByDeletingPathExtension?.lastPathComponent {
                    myDocument.setDisplayName(imageName)
                }
                myDocument.makeWindowControllers()
                myDocument.showWindows()
                return true
            } catch {
                NSLog("failed creating untitled document: \(error)")
                return false
            }
        }

        let type = try! controller.typeForContentsOfURL(URL)
        NSLog("\(file): has type \(type)")
        controller.openDocumentWithContentsOfURL(URL, display: true) {
        (document, alreadyOpen, error) -> Void in
            let result: AnyObject? = document ?? error
            NSLog("opening \(file): already open? \(alreadyOpen) - result \(result)")

            if let error = error {
                NSApp.presentError(error)
            }
        }
        return true
    }
}
