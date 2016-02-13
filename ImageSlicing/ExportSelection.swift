import Quartz

struct ExportSelection {
    let around: CGPoint
    let name: String
}


extension ExportSelection {
    var asDictionary: [String: AnyObject] {
        var dictionary: [String: AnyObject] = [:]
        dictionary["around"] = NSValue(point: around)
        dictionary["name"] = name
        return dictionary
    }

    init?(dictionary: [String: AnyObject]) {
        guard let value = dictionary["around"] as? NSValue else {
            return nil
        }
        around = value.pointValue

        guard let name = dictionary["name"] as? String else {
                return nil
        }
        self.name = name
    }
}
