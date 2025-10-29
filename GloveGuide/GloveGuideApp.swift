//
//  GloveGuideApp.swift
//  GloveGuide
//
//  Created by Mohammad Adnaan on 2025-10-24.
//

import SwiftUI

@main
struct GloveGuideApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Request location permissions on app launch
                    requestLocationPermissions()
                }
        }
    }
    
    private func requestLocationPermissions() {
        // This will be handled by the NavigationManager when it's initialized
        // The location manager setup happens there
    }
}

import CoreLocation

// Extension to handle background location if needed
extension GloveGuideApp {
    func setupBackgroundLocation() {
        // For future enhancement: background location during navigation
    }
}
