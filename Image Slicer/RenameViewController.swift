import Cocoa

class RenameViewController: NSViewController {
    private var completion = {(_: String) -> Void in return}
    private var originalName = "" {
        didSet {
            nameDidChange()
        }
    }

    func configure(name: String, completion: (String) -> Void) {
        originalName = name
        self.completion = completion
    }

    @IBOutlet var nameField: NSTextField!
    @IBAction func okAction(sender: AnyObject) {
        dismissViewController(self)
        completion(nameField.stringValue)

    }
    @IBAction func cancelAction(sender: AnyObject) {
        dismissViewController(self)
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
