//
//  IterableAPIHelper.swift
//  swift-sample-app
//
//  Created by vishwa on 23/05/24.
//  Copyright © 2024 Iterable. All rights reserved.
//

import Foundation
import IterableSDK

public class IterableAPIHelper {

    public static var authType: IterableAPIHelper.AuthType = .VALID
    public static var maxRetry = 10
    public static var currentRetry = 0
    public static var lastRetryTime = "0"

    public enum AuthType {
        case NULL
        case INVALID
        case VALID
        case EXPIRED
    }
}
