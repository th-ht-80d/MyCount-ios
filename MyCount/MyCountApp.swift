//
//  MyCountApp.swift
//  MyCount
//
//  Created by 濱貴大 on 2026/02/05.
//

import SwiftUI

@main
struct MyCountApp: App {
    @StateObject private var store = CountdownStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
