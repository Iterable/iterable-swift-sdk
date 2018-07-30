//
//
//  Created by Tapash Majumder on 7/29/18.
//  Copyright © 2018 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class APNSUtilTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testValidProduction() {
        let path = Bundle(for: type(of:self)).path(forResource: "prod-1", ofType: "mobileprovision")!
        let mobileProvision = IterableAPNSUtil.readMobileProvision(fromPath: path)
        let isSandbox = IterableAPNSUtil.isSandboxAPNS(mobileProvision: mobileProvision, isSimulator: false)
        XCTAssertFalse(isSandbox)
    }
    
    func testDev() {
        let path = Bundle(for: type(of:self)).path(forResource: "dev-1", ofType: "mobileprovision")!
        let mobileProvision = IterableAPNSUtil.readMobileProvision(fromPath: path)
        let isSandbox = IterableAPNSUtil.isSandboxAPNS(mobileProvision: mobileProvision, isSimulator: false)
        XCTAssertTrue(isSandbox)
    }

    func testNoValue() {
        XCTAssertTrue(IterableAPNSUtil.isSandboxAPNS(mobileProvision: [:], isSimulator: true))
        XCTAssertFalse(IterableAPNSUtil.isSandboxAPNS(mobileProvision: [:], isSimulator: false))
    }
}
