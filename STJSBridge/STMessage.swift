//
//  STMessage.swift
//  STJSBridge
//
//  Created by Maple Yin on 04/23/2018.
//  Copyright (c) 2018 Duran. All rights reserved.
//

import Foundation

public struct STError {
    var code: Int
    var message: String
    
    public init(code: Int, message: String) {
        self.code = code
        self.message = message
    }
    
    func json() -> [String:Any] {
        return [
            "code": code,
            "message": message
        ];
    }
}


class STMessage {
    var requestId: Int = 0
    var responseId: Int?
    var name: String?
    var content: Any?
    var error: STError?
    
    init(data: [String:Any]? = nil) {
        if let data = data {
            responseId = data["responseId"] as? Int
            if let name = data["name"] as? String {
                self.name = name;
            }
            content = data["content"];
            if let requestId = data["requestId"] as? Int {
                self.requestId = requestId;
            }
        }
    }
    
    var JSString: String? {
        var info: [String:Any] = [:]
        info["requestId"] = requestId
        info["responseId"] = responseId
        info["name"] = name
        info["content"] = content
        info["error"] = error?.json()
        
        if let data = try? JSONSerialization.data(withJSONObject: info, options: []) {
            return String(data: data, encoding: .utf8)
        } else {
            return nil
        }
    }
}
