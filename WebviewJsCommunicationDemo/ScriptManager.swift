//
//  ScriptManager.swift
//  WebviewJsCommunicationDemo
//
//  Created by Itsuki on 2025/10/17.
//

import SwiftUI
import WebKit


class ScriptManager: NSObject {
    var onThemeSetInWeb: ((Theme) -> Void)?
    var onMultiplierCalled: (() -> Void)?
    var onGetErrorCalled: (() -> Void)?

    // Messages we will be receiving from JavaScript code
    enum MessageName:String {
        // Notify swiftUI that web has updated the theme
        case setTheme
    }
    
    // Messages we will be receiving from JavaScript code as well as responding to
    enum MessageWithReplyName: String {
        case callFunction
    }
    
    // functions available to be called with MessageWithReplyName.callFunction
    enum AvailableFunction: String {
        case multiplier
        case getError
    }
    
    // message keys for postMessage called on MessageWithReplyName.callFunction
    // postMessage({
    //   "\(nameKey)": "some name",
    //   "\(argumentKey)": { key: "value" }
    // })
    private let functionNameKey = "name"
    private let functionArgumentKey = "arguments"

    private let setGlobalEventType = "itsuki:set_globals"
    
    // create WKUserContentController to be used with WebPage
    func createUserContentController(initialTheme: Theme) -> WKUserContentController {
        let contentController = WKUserContentController()

        // script to be injected
        let script =
"""
function setTheme(newTheme) {
    window.itsuki.theme = newTheme
    const event = new CustomEvent("\(self.setGlobalEventType)", {
        detail: {
            globals: {
                theme: newTheme
            }
        }
    })

    window.dispatchEvent(event)
}

window.itsuki = {
    "theme": "\(initialTheme.rawValue)",
    "setTheme": (newTheme) => {
        window.webkit.messageHandlers.\(MessageName.setTheme.rawValue).postMessage(newTheme)
        setTheme(newTheme)
    },
    "callFunction": async (name, value) => {
        return await window.webkit.messageHandlers.\(MessageWithReplyName.callFunction.rawValue).postMessage({
            "\(functionNameKey)": name, 
            "\(functionArgumentKey)": value
        })
    }
}
"""
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        contentController.addUserScript(userScript)

        // Installs a message handler that you can call from your JavaScript code.
        contentController.add(self, name: MessageName.setTheme.rawValue)
        
        // Installs a message handler that returns a reply to your JavaScript code.
        contentController.addScriptMessageHandler(self, contentWorld: .page, name: MessageWithReplyName.callFunction.rawValue)
       
        return contentController
    }
    
    
    // call javascript function from SwiftUI to set theme on the web
    func setTheme(_ theme: Theme, page: WebPage) async throws {
        try await page.callJavaScript("setTheme('\(theme.rawValue)')", contentWorld: .page)
    }

}
 

// MARK: WKScriptMessageHandlerWithReply
// An interface for *responding* to messages from JavaScript code running in a webpage.
extension ScriptManager: WKScriptMessageHandlerWithReply {
    
    // returning (Result, Error)
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) async -> (Any?, String?) {
        print(#function, "WKScriptMessageHandlerWithReply")
        print(message.name)
        
        guard let name: MessageWithReplyName = .init(rawValue: message.name) else {
            return (nil, "Message received from unknown message handler with name: \(message.name)")
        }
        switch name {
        case .callFunction:
            print(message.body)
            return await self.handleCallFunctionCalled(messageBody: message.body)
        }
    }
    
    private func handleCallFunctionCalled(messageBody: Any) async -> (Any?, String?) {
        guard let body = messageBody as? Dictionary<String, Any> else {
            return (nil, "Invalid message body: Has to be in form a key-value object.")
        }
        
        guard let name = body[functionNameKey] as? String, let arguments = body[functionArgumentKey] as? Dictionary<String, Any> else {
            return (nil, "Invalid name or arguments.")
        }
        
        guard let functionName = AvailableFunction(rawValue: name) else {
            return (nil, "Function with name \(name) does not exist. Allowed: \(AvailableFunction.multiplier.rawValue), \(AvailableFunction.getError.rawValue)")
        }
        
        do {
            switch functionName {
                
            case .multiplier:
                let result =  try await handleMultiplierFunctionCalled(arguments: arguments)
                return (result, nil)
            case .getError:
                try await handleGetErrorFunctionCalled()
                return (nil, nil)
            }
        } catch(let error) {
            let error = error as NSError
            return (nil, "Error: \(error.domain). Code: \(error.code)")
        }

    }
    
    private func handleMultiplierFunctionCalled(arguments: Dictionary<String, Any>) async throws -> Double {
        self.onMultiplierCalled?()
        guard let values = arguments["values"] as? Array<Double> else {
            throw NSError(domain: "invalidArgument", code: 400)
        }

        guard var final = values.first else {
            return 0
        }
        for (index, value) in values.enumerated() {
            if index == 0 {
                continue
            }
            final = final * value
        }
        
        return final
    }
    
    private func handleGetErrorFunctionCalled() async throws   {
        self.onGetErrorCalled?()
        throw NSError(domain: "randomError", code: Int.random(in: 400..<500))
    }
}


// MARK: WKScriptMessageHandler
// An interface to receive messages from JavaScript code running in a webpage.
extension ScriptManager: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print(#function, "WKScriptMessageHandler")
        print(message.name)
        
        guard let name: MessageName = .init(rawValue: message.name) else {
            print("Message received from unknown message handler with name: \(message.name)")
            return
        }
        
        switch name {
        case .setTheme:
            self.handleSetThemeCalled(messageBody: message.body)
            return
        }
    }
    
    private func handleSetThemeCalled(messageBody: Any) {
        guard let body = messageBody as? String else {
            print("Invalid message body: expect to be a string.")
            return
        }
        guard let theme: Theme = .init(rawValue: body) else {
            print("Invalid message body: expect to be a theme.")
            return
        }
        self.onThemeSetInWeb?(theme)
    }

}
