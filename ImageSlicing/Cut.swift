//  Copyright © 2016 Jeremy W. Sherman. Released with NO WARRANTY.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Quartz

struct Cut {
    let at: CGPoint
    let oriented: Orientation

    func slice(subimage: Subimage) -> [Subimage] {
        let edge: CGRectEdge
        let amount: CGFloat

        switch oriented {
        case .Horizontally:
            edge = .minYEdge
            amount = at.y - subimage.rect.minY

        case .Vertically:
            edge = .minXEdge
            amount = at.x - subimage.rect.minX
        }

        let (subrect, otherSubrect) = subimage.rect.divided(atDistance: amount, from: edge)
        return [subrect, otherSubrect].map(Subimage.init)
    }
}

extension Cut {
    var asDictionary: [String: AnyObject] {
        var dictionary: [String: AnyObject] = [:]
        dictionary["at"] = NSValue(point: at)
        dictionary["oriented"] = oriented.rawValue as AnyObject
        return dictionary
    }

    init?(dictionary: [String: AnyObject]) {
        guard let value = dictionary["at"] as? NSValue else {
                return nil
        }
        at = value.pointValue

        guard
            let rawValue = dictionary["oriented"] as? String,
            let orientation = Orientation(rawValue: rawValue) else {
                return nil
        }
        oriented = orientation
    }
}


extension Cut: Equatable {}
func ==(left: Cut, right: Cut) -> Bool {
    return left.oriented == right.oriented && left.at.equalTo(right.at)
}
