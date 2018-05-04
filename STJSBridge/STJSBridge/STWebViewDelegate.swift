//
//  STWebViewDelegate.swift
//  STJSBridge
//
//  Created by Duran on 2018/4/26.
//  Copyright © 2018年 Maple.im. All rights reserved.
//
//

import Foundation
import WebKit
import JavaScriptCore


class STWebViewDelegate : NSObject {
    
    weak var webViewDelegate:AnyObject?
    var eventHandler:((Data)->Void)?
    
    
    init(delegate:UIWebViewDelegate) {
        super.init()
        webViewDelegate = delegate
    }
    
    init(delegate:WKNavigationDelegate) {
        super.init()
        webViewDelegate = delegate
    }
    
    
    /// 绑定页面消息处理
    ///
    /// - Parameter handler: 消息处理
    func bindEventHandler(handler:@escaping (Data)->Void) {
        eventHandler = handler
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        var can = super.responds(to: aSelector)
        if !can,let delegate = webViewDelegate {
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
            return jsString;
        }
        return nil
    }
}

extension STWebViewDelegate : UIWebViewDelegate {
    func webViewDidFinishLoad(_ webView: UIWebView) {
        // do inject
        if let injectJS = self.injectJS() {
            webView.stringByEvaluatingJavaScript(from: injectJS)
        }
        
        
        /// 添加 web 发送消息接口
        if let jsContext = webView.value(forKeyPath: kJSContextKeyPath) as? JSContext,
            let eventHandler = eventHandler {
            let bindGlobalVar = "window.__inject__web__message__send__"
            jsContext.setObject(eventHandler, forKeyedSubscript: NSString(string: bindGlobalVar) )
        }
        
        if let delegate = webViewDelegate,
            delegate.responds(to: #selector(webViewDidFinishLoad(_:))) {
            delegate.webViewDidFinishLoad(webView)
        }
    }
}

extension STWebViewDelegate : WKNavigationDelegate,WKScriptMessageHandler {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        // do inject
        if let injectJS = self.injectJS() {
            webView.evaluateJavaScript("window.__inject__web__message__send__key__ = \"\(kScriptMessageHandlerName)\";\(injectJS);" ){ (content, error) in
                print("\(content,error)")
            }
        }
        /// 添加 web 发送消息接口
        webView.configuration.userContentController.add(self, name: kScriptMessageHandlerName)
        
        if let delegate = webViewDelegate,
            delegate.responds(to: #selector(webView(_:didFinish:))) {
            delegate.webView(webView, didFinish: navigation)
        }
    }
    
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == kScriptMessageHandlerName,
            let eventHandler = eventHandler {
            if let str = message.body as? String {
                
                eventHandler(str.data(using: .utf8)!)
            }
        }
    }
    
}
