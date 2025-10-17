//
//  ContentView.swift
//  WebviewJsCommunicationDemo
//
//  Created by Itsuki on 2025/10/16.
//

import SwiftUI
import WebKit

struct ContentView: View {
        
    @State private var webpage: WebPage?
    @State private var theme: Theme = .dark
    @State private var lastFunctionCalled: String? = nil
    @State private var setThemeError: Error?
    
    private let url: URL? = URL(string: "http://localhost:4444")
    private let scriptManager: ScriptManager = ScriptManager()

    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("SwiftUI")
                .font(.title3)
                .fontWeight(.bold)

            VStack(alignment: .leading) {
                
                Text("Call JS Function")
                    .font(.headline)
                HStack {
                    Button(action: {
                        guard let page = self.webpage else {
                            return
                        }
                        let targetTheme: Theme = self.theme == .dark ? .light : .dark
                        Task {
                            do {
                                try await scriptManager.setTheme(targetTheme, page: page)
                                self.theme = targetTheme
                            } catch (let error) {
                                print(error)
                                self.setThemeError = error
                            }
                        }
                    }, label: {
                        Text("Change Theme")
                    })
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle)

                    Text("Theme: \(self.theme.rawValue)")
                }
                
                if let setThemeError {
                    Text("Error: \(setThemeError.localizedDescription)")
                        .foregroundStyle(.red)
                }
                
                Divider()
                
                Text("Swift Functions Called from JS")
                    .font(.headline)
                Group {
                    if let lastFunctionCalled {
                        Text("\(lastFunctionCalled) Called!")
                    } else {
                        Text("No function called yet.")
                    }
                }
                .foregroundStyle(.secondary)
            }
            .padding(.all, 16)
            .background(RoundedRectangle(cornerRadius: 8).fill(.background))
            .colorScheme(self.theme == .dark ? .dark : .light)

            RoundedRectangle(cornerRadius: 4)
                .fill(.gray.opacity(0.5))
                .frame(height: 2)
            
            
            Text("Webview")
                .font(.title3)
                .fontWeight(.bold)
            
            VStack {

                if let webpage = self.webpage {
                    WebView(webpage)
                        .webViewContentBackground(.hidden)
                        .overlay(content: {
                            if webpage.isLoading {
                                ProgressView()
                                    .controlSize(.large)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(.yellow.opacity(0.1))
                            }
                        })
                } else {
                    Text("Web page is going somewhere else...")
                }
            }

        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.yellow.opacity(0.1))
        .onAppear {
            self.initWebpage()
        }
    }
    
    
    private func initWebpage() {
        var configuration = WebPage.Configuration()
        
        var navigationPreference = WebPage.NavigationPreferences()
        
        navigationPreference.allowsContentJavaScript = true
        navigationPreference.preferredHTTPSNavigationPolicy = .keepAsRequested
        navigationPreference.preferredContentMode = .mobile
        configuration.defaultNavigationPreferences = navigationPreference

        // userContentController: An object for managing interactions between JavaScript code and your web view, and for filtering content in your web view.
        configuration.userContentController = self.scriptManager.createUserContentController(initialTheme: self.theme)
        
        // set up handlers
        self.scriptManager.onThemeSetInWeb = { self.theme = $0 }
        self.scriptManager.onMultiplierCalled = { self.lastFunctionCalled = ScriptManager.AvailableFunction.multiplier.rawValue }
        self.scriptManager.onGetErrorCalled = { self.lastFunctionCalled = ScriptManager.AvailableFunction.getError.rawValue }

        let page = WebPage(configuration: configuration)
        self.webpage = page
        
        guard let url = self.url else {
            return
        }
        
        page.load(URLRequest(url: url))
    }

}


//#Preview {
//    ContentView()
//}
