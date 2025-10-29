//
//  AppCoordinator.swift
//  GloveGuide
//
//  Created by Mohammad Adnaan on 2025-10-26.
//

import Foundation
import MapKit
import SwiftUI
import Combine

@MainActor
class AppCoordinator: ObservableObject {
    // MARK: - Managers
    let bluetoothManager = BluetoothManager()
    @Published var settings = AppSettings()
    private(set) lazy var navigationManager = NavigationManager(bluetoothManager: bluetoothManager, settings: settings)
    
    // MARK: - UI State
    @Published var currentScreen: AppScreen = .home
    @Published var showingSettings = false
    @Published var showingEndNavigation = false
    @Published var errorMessage: String?
    @Published var showingError = false
    
    init() {
        // Set up navigation state observation
        setupNavigationObserver()
    }
    
    private func setupNavigationObserver() {
        navigationManager.$navigationState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .idle:
                    self?.currentScreen = .home
                case .navigating:
                    self?.currentScreen = .navigation
                case .arrived:
                    self?.showingEndNavigation = true
                case .searchingRoute:
                    // Stay on current screen while searching
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Actions
    func startNavigation(to destination: MKMapItem) {
        Task {
            await navigationManager.calculateRoute(to: destination)
        }
    }
    
    func endNavigation() {
        navigationManager.stopNavigation()
        showingEndNavigation = false
        currentScreen = .home
    }
    
    func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

enum AppScreen {
    case home
    case navigation
    case settings
}