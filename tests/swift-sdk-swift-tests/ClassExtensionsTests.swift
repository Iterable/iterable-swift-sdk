//
//  Created by Jay Kim on 6/6/19.
//  Copyright © 2019 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

typealias Byte = UInt8

class ClassExtensionsTests: XCTestCase {
    func testUIColorInit() {
        let blackColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        guard let hexColor = UIColor(hex: "000000") else {
            XCTFail("ERROR: UIColor init by hex failed")
            return
        }
        
        XCTAssertEqual(hexColor, blackColor)
    }
    
    func testHexConversion() {
        10.times {
            let token = generateToken()
            let hex = token.hexString()
            XCTAssertEqual(token, data(fromHexString: hex))
        }
    }
    
    private func generateRandomInt(max: Int) -> Int {
        Int(arc4random_uniform(UInt32(max)))
    }
    
    private func generateToken() -> Data {
        var byteArray = [Byte]()
        
        32.times {
            byteArray.append(Byte(generateRandomInt(max: 256)))
        }
        
        return Data(byteArray)
    }
    
    // maps a hex char to corresponding digit
    // e.g., a -> 10, b -> 11
    private func hexCharToDigit(_ hexChar: Character) -> Byte? {
        let digits = Array("0123456789abcdef")
        return digits.firstIndex(of: hexChar).map { Byte($0) }
    }
    
    // takes 2 hexadecimal characters and convert it to a single byte
    private func hexCharsToByte(c1: Character, c2: Character) -> (Byte)? {
        guard let d1 = hexCharToDigit(c1), let d2 = hexCharToDigit(c2) else {
            return nil
        }
        return d1 * 16 + d2
    }
    
    // convert string of hexadecimal characters into a combination of bytes
    // assembles combination of bytes by converting every 2 characters
    private func data(fromHexString hexString: String) -> Data {
        Data(Array(hexString).take(2).map { hexCharsToByte(c1: $0[0], c2: $0[1]) }.compactMap { $0 })
    }
}
