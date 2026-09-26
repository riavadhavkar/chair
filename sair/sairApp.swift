//
//  sairApp.swift
//  sair
//
//  Created by ria vadhavkar on 9/26/26.
//

import SwiftUI

@main
struct sairApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    var body: some Scene {
        #if os(macOS)
        Settings {
            EmptyView()
        }
        #else
        WindowGroup {
            ContentView()
        }
        #endif
    }
}
