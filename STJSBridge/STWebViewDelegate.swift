//
//  STWebViewDelegate.swift
//  STJSBridge
//
//  Created by Maple Yin on 04/23/2018.
//  Copyright (c) 2018 Duran. All rights reserved.
//

import Foundation
import WebKit


class STWebViewDelegate : NSObject {
    
    weak var webViewDelegate: AnyObject?
    var eventHandler: (([String:Any]) -> Void)?
    private(set) var scriptMessageHandlerName: String?
    
    init(delegate: WKNavigationDelegate) {
        super.init()
        webViewDelegate = delegate
        scriptMessageHandlerName = String(self.hash)
    }
    
    /// 绑定页面消息处理
    ///
    /// - Parameter handler: 消息处理
    func bindEventHandler(handler: @escaping ([String:Any])->Void) {
        eventHandler = handler
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        var can = super.responds(to: aSelector)
        if !can, let delegate = webViewDelegate {
            can = delegate.responds(to: aSelector)
        }
        return can
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return webViewDelegate
    }
    
    
    func injectJS() -> String? {
        if let filePath = Bundle.init(for: STWebViewDelegate.self).path(forResource: "STJSBridge", ofType: "js"),
            let jsString = try? String(contentsOfFile: filePath, encoding: .utf8){
            return jsString
        }
        return nil
    }
}

// MARK: - WKNavigationDelegate,WKScriptMessageHandler
extension STWebViewDelegate : WKNavigationDelegate,WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == scriptMessageHandlerName,
            let eventHandler = eventHandler {
            if let info = message.body as? [String:Any] {
                eventHandler(info)
            }
        }
    }
}
