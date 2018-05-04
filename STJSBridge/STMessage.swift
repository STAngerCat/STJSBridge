//
//  STMessage.swift
//  STJSBridge
//
//  Created by Duran on 2018/4/23.
//  Copyright © 2018年 Maple.im. All rights reserved.
//

import Foundation

class STMessage {
    var requestId:Int = 0
    var responseId:Int?
    var name:String?
    var content:Any?
    
    init(data:[String:Any]? = nil) {
        if let data = data {
            responseId = data["responseId"] as? Int;
            if let name = data["name"] as? String {
                self.name = name;
            }
            content = data["content"];
            if let requestId = data["requestId"] as? Int {
                self.requestId = requestId;
            }
        }
    }
    
    var JSString:String? {
        var info:[String:Any] = [:]
        info["requestId"] = requestId
        info["responseId"] = responseId
        info["name"] = name
        info["content"] = content
        
        if let data = try? JSONSerialization.data(withJSONObject: info, options: .init(rawValue: 0)) {
            return String(data: data, encoding: .utf8)
        } else {
            return nil
        }
    }
}
