//
//  sairApp.swift
//  sair
//
//  Created by ria vadhavkar on 9/26/26.
//

import SwiftUI

@main
struct sairApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
