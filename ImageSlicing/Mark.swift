//  Copyright © 2016 Jeremy W. Sherman. Released with NO WARRANTY.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Quartz

struct Mark {
    let around: CGPoint
    let name: String
}


extension Mark {
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


extension Mark: Equatable {}
func ==(left: Mark, right: Mark) -> Bool {
    return CGPointEqualToPoint(left.around, right.around) && left.name == right.name
}
