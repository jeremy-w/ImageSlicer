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

        // Do any additional setup after loading the view.
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
}



// MARK: - Mark Management
extension ViewController {

}



// MARK: - Export
extension ViewController {

}