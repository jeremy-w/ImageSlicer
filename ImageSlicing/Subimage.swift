//  Copyright © 2016 Jeremy W. Sherman. Released with NO WARRANTY.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Quartz

struct Subimage {
    let rect: CGRect

    func contains(point: CGPoint) -> Bool {
        return rect.contains(point)
    }
}
