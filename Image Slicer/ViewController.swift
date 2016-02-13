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

