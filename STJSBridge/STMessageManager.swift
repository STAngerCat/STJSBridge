//
//  STMessageManager.swift
//  STJSBridge
//
//  消息处理
//
//  Created by Maple Yin on 04/23/2018.
//  Copyright (c) 2018 Duran. All rights reserved.
//

import Foundation
import WebKit

let kWebMessageSendFuncKey = "window.__inject__native_message__send__"

public typealias BaseCallBack = (Any?, STError?) -> Void
public typealias MessageCallBack = (Any?, BaseCallBack?) -> Void

class STMessageManager : NSObject {
    
    weak var wkwebview: WKWebView?
    
    
    /// 对 webview 的统一处理
    var delegate: STWebViewDelegate
    
    
    /// 监听的消息列表
    var eventList: [String : [MessageCallBack]] = [:]
    
    var callBackList: [Int : BaseCallBack] = [:];
    
    /// 对于没有特定名字的监听
    var noneNameEventHandler: MessageCallBack?
    
    
    /// 消息 id
    var requestId = 0
    
    init(with webview: WKWebView, delegate: WKNavigationDelegate) {
        self.delegate = STWebViewDelegate(delegate: delegate)
        super.init()
        self.wkwebview = webview
        self.wkwebview?.navigationDelegate = self.delegate
        
        self.delegate.bindEventHandler { [weak self] (info) in
            self?.fromWebToClient(info: info)
        }
        self.injectJSForWKWebView()
    }
    
    deinit {
        let handlerName = self.delegate.scriptMessageHandlerName ?? ""
        self.wkwebview?.configuration.userContentController.removeScriptMessageHandler(forName: handlerName)
    }
    
    
    /// 处理来自客户端的消息
    ///
    /// - Parameters:
    ///   - name: 事件名
    ///   - content: 内容
    ///   - then: 回调
    func fromClientToWeb(name: String, content: Any?, then: BaseCallBack?) {
        requestId = requestId + 1
        let message = STMessage()
        message.name = name
        message.requestId = requestId
        message.content = content
        
        if let then = then {
            callBackList[requestId] = then
        }
        sendMessage(message: message)
    }

    
    /// 来自 Web 端的消息
    ///
    /// - Parameter data: 消息字典
    func fromWebToClient(info: [String:Any]) {
        let message = STMessage(data: info)
        if let responseId = message.responseId,
            let callBack = callBackList[responseId] {
            callBack(message.content,message.error)
        } else if let name = message.name {
            if let eventHanlders = eventList[name] {
                eventHanlders.forEach { (handler) in
                    handler(message.content) { content, error in
                        self.responseToMessage(messageId: message.requestId, content: content, error: error)
                    }
                }
            }
        } else if let messageEventHandler = noneNameEventHandler {
            messageEventHandler(message.content) { content, error in
                self.responseToMessage(messageId: message.requestId, content: content, error: error)
            }
        }
    }

    
    
    /// 对消息的结果响应
    ///
    /// - Parameters:
    ///   - message: 响应的消息
    ///   - content: 内容
    func responseToMessage(messageId: Int,content: Any?,error: STError?) {
        let responseMessage = STMessage()
        responseMessage.responseId = messageId
        responseMessage.content = content
        responseMessage.error = error
        sendMessage(message: responseMessage)
    }
    
    
    /// 添加事件监听
    ///
    /// - Parameters:
    ///   - name: 事件名
    ///   - handler: 回调处理
    func addEventListener(name: String? ,handler: @escaping MessageCallBack) {
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
    func sendMessage(message: STMessage) -> Void {
        
        if let wkwebview = wkwebview,
            let JSString = message.JSString {
            wkwebview.evaluateJavaScript( "\(kWebMessageSendFuncKey)(\(JSString))", completionHandler: nil)
        }
    }
    
    
    
    private func injectJSForWKWebView() {
        
        let handlerName = self.delegate.scriptMessageHandlerName ?? ""
        
        // do inject
        if var injectJS = self.delegate.injectJS() {
            if let range = injectJS.range(of: "###replace_message_key###") {
                injectJS.replaceSubrange(range, with: handlerName)
            }
            let userScript = WKUserScript(source: injectJS, injectionTime: .atDocumentStart, forMainFrameOnly: true)
            self.wkwebview?.configuration.userContentController.addUserScript(userScript)
        }
        
        self.wkwebview?.configuration.userContentController.add(self.delegate, name: handlerName)
    }
}
