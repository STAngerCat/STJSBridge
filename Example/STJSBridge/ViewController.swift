//
//  ViewController.swift
//  STJSBridge
//
//  Created by Duran on 04/23/2018.
//  Copyright (c) 2018 Duran. All rights reserved.
//

import UIKit
import STJSBridge
import WebKit

class ViewController: UIViewController {
    
    var jsbridge:STJSBridge?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let configuration = WKWebViewConfiguration()
        
        configuration.requiresUserActionForMediaPlayback = false
        
        let webView = WKWebView(frame: view.bounds, configuration: configuration)
        
        jsbridge = STJSBridge(with: webView, delegate: self)
        
        view.addSubview(webView)
        let bundle = Bundle.main
        if let filePath = bundle.path(forResource: "index", ofType: "html"),
            let HTMLString = try? String(contentsOfFile: filePath, encoding: .utf8) {
            webView.loadHTMLString(HTMLString, baseURL: nil)
        }
        
        
        jsbridge?.addEventHandler(name: "show", handler: { (content, callback) in
            
        })
        
        jsbridge?.sendMessage(name: "aloha",content: "Form Client Message", then: { (content) in
            print("formWebCallBackMessage:\(String(describing: content))")
        })
        
        
        let button = UIButton(type: .contactAdd);
        view.addSubview(button);
        
        button.addTarget(self, action: #selector(buttonClick), for: .touchUpInside);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @objc func buttonClick(){
        jsbridge?.sendMessage(name: "aloha",content: "Form Client Message", then: { (content) in
            print("formWebCallBackMessage:\(String(describing: content))")
        })
    }
}


extension ViewController:UIWebViewDelegate {
    @objc func webViewDidFinishLoad(_ webView: UIWebView) {
        print("webViewDidFinishLoad")
    }
}


extension ViewController:WKNavigationDelegate {
    
}

