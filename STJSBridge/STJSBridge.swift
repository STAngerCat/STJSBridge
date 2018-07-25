//
//  STJSBridge.swift
//  STJSBridge
//
//  Created by Maple Yin on 04/23/2018.
//  Copyright (c) 2018 Duran. All rights reserved.
//

import Foundation
import WebKit

public class STJSBridge {
    
    private let messageManager: STMessageManager
    
    public init(with webView: WKWebView, delegate: WKNavigationDelegate) {
        messageManager = STMessageManager(with: webView, delegate: delegate)
    }
}

// MARK:- Message
public extension STJSBridge {
    
    /// 发消息给前端页面 Client -> Web
    ///
    /// - Parameters:
    ///   - name: 消息签名
    ///   - params: 消息参数
    ///   - then: 消息执行结果回调
    public func sendMessage(name: String, content: Any? = nil, then: BaseCallBack? = nil) {
        messageManager.fromClientToWeb(name: name, content: content, then:then)
    }
    
    /// 添加前端页面的消息监听
    ///
    /// - Parameter handler: 消息监听处理
    public func addEventHandler(name: String? = nil, handler: @escaping MessageCallBack) {
        messageManager.addEventListener(name: name, handler: handler)
    }
}
