// We need this file due to a codecov.io bug where no coverage is generated if
// we have just one swift file. We add this file to generate coverage.
// TODO: in future remove this file when the codecov bug is fixed.
//
//  Copyright © 2018 Iterable. All rights reserved.
//
import Foundation

class TestFile {
    func sayHello() {
        NSLog("Hello, World!")
    }
}
