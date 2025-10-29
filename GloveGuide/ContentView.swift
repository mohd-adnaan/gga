//
//  ContentView.swift
//  GloveGuide
//
//  Created by Mohammad Adnaan on 2025-10-24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var coordinator = AppCoordinator()
    
    var body: some View {
        ZStack {
            // Main content based on current screen
            switch coordinator.currentScreen {
            case .home:
                HomeView(coordinator: coordinator)
            case .navigation:
                NavigationActiveView(coordinator: coordinator)
            case .settings:
                SettingsView(coordinator: coordinator)
            }
            
            // End navigation overlay
            if coordinator.showingEndNavigation {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Prevent dismissing by tapping background
                    }
                
                EndNavigationView(
                    coordinator: coordinator,
                    isPresented: $coordinator.showingEndNavigation
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.showingEndNavigation)
        .alert("Error", isPresented: $coordinator.showingError) {
            Button("OK") {
                coordinator.showingError = false
            }
        } message: {
            Text(coordinator.errorMessage ?? "An unknown error occurred")
        }
    }
}

#Preview {
    ContentView()
}
