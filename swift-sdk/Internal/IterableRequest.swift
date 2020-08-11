//
//  Created by Tapash Majumder on 7/29/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import Foundation

// These are Iterable specific Request items.
// They don't have Api endpoint and request endpoint defined yet.
enum IterableRequest {
    case get(GetRequest)
    case post(PostRequest)
}

extension IterableRequest: Codable {
    enum CodingKeys: String, CodingKey {
        case type
        case value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case IterableRequest.requestTypeGet:
            let request = try container.decode(GetRequest.self, forKey: .value)
            self = .get(request)
        case IterableRequest.requestTypePost:
            let request = try container.decode(PostRequest.self, forKey: .value)
            self = .post(request)
        default:
            throw IterableError.general(description: "Unknown request type: \(type)")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .get(let request):
            try container.encode(IterableRequest.requestTypeGet, forKey: .type)
            try container.encode(request, forKey: .value)
        case .post(let request):
            try container.encode(IterableRequest.requestTypePost, forKey: .type)
            try container.encode(request, forKey: .value)
        }
    }

    private static let requestTypeGet = "get"
    private static let requestTypePost = "post"
}

struct GetRequest: Codable {
    let path: String
    let args: [String: String]?
}

struct PostRequest {
    let path: String
    let args: [String: String]?
    let body: [AnyHashable: Any]?
}

extension PostRequest: Codable {
    enum CodingKeys: String, CodingKey {
        case path
        case args
        case body
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let path = try container.decode(String.self, forKey: .path)
        let args = try container.decode([String: String]?.self, forKey: .args)
        let body: [AnyHashable: Any]?
        if let bodyData = try container.decode(Data?.self, forKey: .body) {
            body = try JSONSerialization.jsonObject(with: bodyData, options: []) as? [AnyHashable: Any]
        } else {
            body = nil
        }
        self.path = path
        self.args = args
        self.body = body
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(path, forKey: .path)
        try container.encode(args, forKey: .args)
        var bodyData: Data? = nil
        if let body = self.body, JSONSerialization.isValidJSONObject(body) {
            bodyData = try JSONSerialization.data(withJSONObject: body, options: [])
        }
        try container.encode(bodyData, forKey: .body)
    }
}


