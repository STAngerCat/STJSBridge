//
//  STMessageManager.swift
//  STJSBridge
//
//  消息处理
//
//  Created by Duran on 2018/4/26.
//  Copyright © 2018年 Maple.im. All rights reserved.
//

import Foundation
import WebKit
import JavaScriptCore

let kJSContextKeyPath = "documentView.webView.mainFrame.javaScriptContext"
let kScriptMessageHandlerName = "kScriptMessageHandlerName"
let kWebMessageSendFuncKey = "window.__inject__native_message__send__"

public typealias BaseCallBack = (Any?)->Void
public typealias MessageCallBack = (Any?,BaseCallBack?)->Void

class STMessageManager:NSObject {
    
    weak var uiwebView:UIWebView?
    weak var wkwebview:WKWebView?
    var jsContext:JSContext?
    
    
    /// 对 webview 的统一处理
    var delegate:STWebViewDelegate
    
    
    /// 监听的消息列表
    var eventList:[String:[MessageCallBack]] = [:]
    
    var callBackList:[Int:BaseCallBack] = [:];
    
    /// 对于没有特定名字的监听
    var noneNameEventHandler:MessageCallBack?
    
    
    /// 消息 id
    var requestId = 0
    
    init(with webview:UIWebView, delegate:UIWebViewDelegate) {
        self.delegate = STWebViewDelegate(delegate: delegate)
        super.init()
        self.uiwebView = webview
        self.uiwebView?.delegate = self.delegate
        self.jsContext = webview.value(forKeyPath: kJSContextKeyPath) as? JSContext
        
        self.delegate.bindEventHandler(handler: fromWebToClient)
        
    }
    
    init(with webview:WKWebView, delegate:WKNavigationDelegate) {
        self.delegate = STWebViewDelegate(delegate: delegate)
        super.init()
        self.wkwebview = webview
        self.wkwebview?.navigationDelegate = self.delegate
        
        self.delegate.bindEventHandler(handler: fromWebToClient)
    }
    
    
    /// 处理来自客户端的消息
    ///
    /// - Parameters:
    ///   - name: 事件名
    ///   - content: 内容
    ///   - then: 回调
    func fromClientToWeb(name:String, content:Any?, then: BaseCallBack?) {
        requestId = requestId + 1
        let message = STMessage()
        message.name = name
        message.requestId = requestId
        message.content = content
        
        if let then = then {
            callBackList[requestId] = then;
        }
        sendMessage(message: message)
    }

    
    /// 来自 Web 端的消息
    ///
    /// - Parameter data: 消息字典
    func fromWebToClient(data:Data) {
        if let dataDic = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any] {
            let message = STMessage(data: dataDic)
            if let responseId = message.responseId,
                let callBack = callBackList[responseId] {
                callBack(message.content)
            } else if let name = message.name,
                let eventHanlders = eventList[name] {
                eventHanlders.forEach { (handler) in
                    handler(message.content) { content in
                        self.responseToMessage(message: message, content: content)
                    }
                }
            } else if let messageEventHandler = noneNameEventHandler {
                messageEventHandler(message.content) { content in
                    self.responseToMessage(message: message, content: content)
                }
            }
        }
    }
    
    
    /// 对消息的结果响应
    ///
    /// - Parameters:
    ///   - message: 响应的消息
    ///   - content: 内容
    func responseToMessage(message:STMessage,content:Any?) {
        let responseMessage = STMessage()
        responseMessage.responseId = message.requestId
        responseMessage.content = content
        sendMessage(message: responseMessage)
    }
    
    
    /// 添加事件监听
    ///
    /// - Parameters:
    ///   - name: 事件名
    ///   - handler: 回调处理
    func addEventListener(name:String? ,handler:@escaping MessageCallBack) {
        if let name = name {
            if var events = self.eventList[name] {
                events.append(handler)
            } else {
                self.eventList[name] = [handler]
            }
        } else {
            noneNameEventHandler = handler
        }
    }
    
    
    /// 发送消息到 Web
    ///
    /// - Parameter message: 消息内容
    func sendMessage(message:STMessage) -> Void {
        
        if let jsContext = jsContext ,
            let JSString = message.JSString{
            jsContext.evaluateScript( "\(kWebMessageSendFuncKey)(\(JSString))")
        } else if let wkwebview = wkwebview,
            let JSString = message.JSString {
            wkwebview.evaluateJavaScript( "\(kWebMessageSendFuncKey)(\(JSString))", completionHandler: nil)
        }
    }
}
