//
//  Hitze_VApp.swift
//  Hitze-V
//
//  Created by Thomas Entner on 04.03.26.
//

import SwiftUI

@main
struct Hitze_VApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("app.theme") private var themeRawValue = AppTheme.system.rawValue
    
    @State private var isShowingLaunchScreen = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color("LaunchBackground")
                    .ignoresSafeArea()

                ContentView()
                    .preferredColorScheme(AppTheme(rawValue: themeRawValue)?.colorScheme)
                
                if isShowingLaunchScreen {
                    LaunchView(isPresented: $isShowingLaunchScreen)
                        .transition(.opacity)
                        .zIndex(1) // Ensure it stays on top while fading out
                }
            }
            .animation(.easeInOut(duration: 0.4), value: isShowingLaunchScreen)
        }
    }
}
