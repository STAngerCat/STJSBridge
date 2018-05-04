//
//  STJSBridge.swift
//  STJSBridge
//
//
//  Created by Duran on 2018/4/23.
//  Copyright © 2018年 Maple.im. All rights reserved.
//

import Foundation
import WebKit

public class STJSBridge {
    
    let messageManager:STMessageManager
    
    public init(with webView:UIWebView, delegate:UIWebViewDelegate) {
        messageManager = STMessageManager(with: webView, delegate: delegate)
    }
    
    public init(with webView:WKWebView, delegate:WKNavigationDelegate) {
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
    public func sendMessage(name:String, content:Any? = nil, then: BaseCallBack? = nil) {
        messageManager.fromClientToWeb(name: name, content: content, then:then)
    }
    
    /// 添加前端页面的消息监听
    ///
    /// - Parameter handler: 消息监听处理
    public func addEventHandler(name:String? = nil, handler:@escaping MessageCallBack) {
        messageManager.addEventListener(name: name, handler: handler)
    }
}
