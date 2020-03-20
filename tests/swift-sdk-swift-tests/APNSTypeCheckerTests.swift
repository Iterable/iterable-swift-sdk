//
//  Created by Tapash Majumder on 7/29/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class APNSTypeCheckerTests: XCTestCase {
    func testValidProduction() {
        let path = Bundle(for: type(of: self)).path(forResource: "prod-1", ofType: "mobileprovision")!
        let mobileProvision = APNSTypeChecker.readMobileProvision(fromPath: path)
        let isSandbox = APNSTypeChecker.isSandboxAPNS(mobileProvision: mobileProvision, isSimulator: false)
        XCTAssertFalse(isSandbox)
    }
    
    func testDev() {
        let path = Bundle(for: type(of: self)).path(forResource: "dev-1", ofType: "mobileprovision")!
        let mobileProvision = APNSTypeChecker.readMobileProvision(fromPath: path)
        let isSandbox = APNSTypeChecker.isSandboxAPNS(mobileProvision: mobileProvision, isSimulator: false)
        XCTAssertTrue(isSandbox)
    }
    
    func testNoValue() {
        XCTAssertTrue(APNSTypeChecker.isSandboxAPNS(mobileProvision: [:], isSimulator: true))
        XCTAssertFalse(APNSTypeChecker.isSandboxAPNS(mobileProvision: [:], isSimulator: false))
    }
}
