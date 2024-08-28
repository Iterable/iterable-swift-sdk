//
//  NestedFieldSupportForArrayData.swift
//  unit-tests
//
//  Created by Apple on 27/08/24.
//  Copyright © 2024 Iterable. All rights reserved.
//

import XCTest
@testable import IterableSDK

final class NestedFieldSupportForArrayData: XCTestCase {
    //MARK: Comparator test For End
    private let mockData = """
       {
         "count": 1,
         "criterias": [
           {
               "criteriaId": "168",
               "name": "nested testing",
               "createdAt": 1721251169153,
               "updatedAt": 1723488175352,
               "searchQuery": {
                   "combinator": "And",
                   "searchQueries": [
                       {
                           "combinator": "And",
                           "searchQueries": [
                               {
                                   "dataType": "user",
                                   "searchCombo": {
                                       "combinator": "And",
                                       "searchQueries": [
                                           {
                                               "dataType": "user",
                                               "field": "furniture",
                                               "comparatorType": "IsSet",
                                               "value": "",
                                               "fieldType": "nested"
                                           },
                                           {
                                               "dataType": "user",
                                               "field": "furniture.furnitureColor",
                                               "comparatorType": "IsSet",
                                               "value": "",
                                               "fieldType": "string"
                                           },
                                           {
                                               "dataType": "user",
                                               "field": "furniture.furnitureType",
                                               "comparatorType": "Equals",
                                               "value": "Sofa",
                                               "fieldType": "string"
                                           }
                                       ]
                                   }
                               }
                           ]
                       }
                   ]
               }
           }
         ]
       }
    """

    override func setUp() {
        super.setUp()
    }

    func data(from jsonString: String) -> Data? {
        return jsonString.data(using: .utf8)
    }

    func testNestedFieldSuccess() {

        let eventItems: [[AnyHashable: Any]] = [
            [
                "dataType":"user",
                 "email":"user@example.com",
                 "dataFields":[
                    "furniture": [
                        [
                            "furnitureType": "Sofa",
                            "furnitureColor": "White",
                            "lengthInches": 40,
                            "widthInches": 60
                        ],
                        [
                            "furnitureType": "Sofa",
                            "furnitureColor": "Gray",
                            "lengthInches": 20,
                            "widthInches": 30
                        ],
                    ]
                ]
            ]
        ]


        let expectedCriteriaId = "168"
        let matchedCriteriaId = CriteriaCompletionChecker(anonymousCriteria: data(from: mockData)!, anonymousEvents: eventItems).getMatchedCriteria()
        XCTAssertEqual(matchedCriteriaId, expectedCriteriaId)
    }

    func testNestedFieldFailed() {

        let eventItems: [[AnyHashable: Any]] = [
            [
                "dataType":"user",
                 "email":"user@example.com",
                 "dataFields":[
                    "furniture": [
                        [
                            "furnitureType": "Sofa",
                            "furnitureColor": "White",
                            "lengthInches": 40,
                            "widthInches": 60
                        ],
                        [
                            "furnitureType": "Table",
                            "furnitureColor": "Gray",
                            "lengthInches": 20,
                            "widthInches": 30
                        ],
                    ]
                ]
            ]
        ]

        let matchedCriteriaId = CriteriaCompletionChecker(anonymousCriteria: data(from: mockData)!, anonymousEvents: eventItems).getMatchedCriteria()
        XCTAssertEqual(matchedCriteriaId, nil)
    }
}
