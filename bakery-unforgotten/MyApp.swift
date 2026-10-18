//
//  MyApp.swift
//  bakery-unforgotten
//
//  Entry point. The original Xcode template pointed at a "Hello, world!"
//  ContentView; BakeCheck now owns the window.
//

import SwiftUI

@main struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            BakeCheckRootView()
        }
    }
}
