//
//  NavigationManager.swift
//  GloveGuide
//
//  Created by Mohammad Adnaan on 2025-10-26.
//

import Foundation
import MapKit
import CoreLocation
import Combine

class NavigationManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var currentLocation: CLLocation?
    @Published var currentRoute: MKRoute?
    @Published var navigationState: NavigationState = .idle
    @Published var currentStepIndex = 0
    @Published var distanceToNextTurn: CLLocationDistance = 0
    @Published var remainingDistance: CLLocationDistance = 0
    @Published var estimatedTimeOfArrival: Date?
    @Published var remainingTime: TimeInterval = 0
    @Published var currentHeading: CLLocationDirection = 0
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var routeSteps: [MKRoute.Step] = []
    private var nextTurnLocation: CLLocation?
    private let bluetoothManager: BluetoothManager
    private let settings: AppSettings
    private var lastHapticCommandSent: HapticCommand?
    private var hapticCommandSentAt: Date?
    
    init(bluetoothManager: BluetoothManager, settings: AppSettings) {
        self.bluetoothManager = bluetoothManager
        self.settings = settings
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    // MARK: - Public Methods
    func calculateRoute(to destination: MKMapItem) async {
        guard let currentLocation = currentLocation else {
            print("Current location not available")
            return
        }
        
        navigationState = .searchingRoute
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: currentLocation.coordinate))
        request.destination = destination
        
        // Set transport type based on settings
        switch settings.transportMode {
        case .walking:
            request.transportType = .walking
        case .cycling:
            request.transportType = .walking // Use walking for cycling as it gives better paths
        }
        
        let directions = MKDirections(request: request)
        
        do {
            let response = try await directions.calculate()
            if let route = response.routes.first {
                await MainActor.run {
                    self.currentRoute = route
                    self.routeSteps = route.steps
                    self.currentStepIndex = 0
                    self.calculateNavigationInfo()
                    self.navigationState = .navigating
                }
            }
        } catch {
            print("Route calculation failed: \(error)")
            await MainActor.run {
                self.navigationState = .idle
            }
        }
    }
    
    func startNavigation() {
        guard currentRoute != nil else { return }
        navigationState = .navigating
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    func stopNavigation() {
        navigationState = .idle
        currentRoute = nil
        routeSteps = []
        currentStepIndex = 0
        bluetoothManager.sendHapticCommand(.stop)
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    // MARK: - Private Methods
    private func calculateNavigationInfo() {
        guard let route = currentRoute,
              let currentLocation = currentLocation else { return }
        
        // Calculate remaining distance and time
        remainingDistance = route.distance
        remainingTime = route.expectedTravelTime
        
        // Calculate ETA
        estimatedTimeOfArrival = Date().addingTimeInterval(remainingTime)
        
        // Find next turn
        updateNextTurn(from: currentLocation)
    }
    
    private func updateNextTurn(from location: CLLocation) {
        guard currentStepIndex < routeSteps.count else {
            // Navigation complete
            navigationState = .arrived
            bluetoothManager.sendHapticCommand(.arrived)
            return
        }
        
        let currentStep = routeSteps[currentStepIndex]
        let stepLocation = CLLocation(latitude: currentStep.polyline.coordinate.latitude,
                                    longitude: currentStep.polyline.coordinate.longitude)
        
        distanceToNextTurn = location.distance(from: stepLocation)
        
        // Check if we need to send haptic feedback
        checkForHapticFeedback(currentStep: currentStep, distanceToTurn: distanceToNextTurn)
        
        // Check if we've passed this step
        if distanceToNextTurn < 10 { // 10 meters threshold
            currentStepIndex += 1
            if currentStepIndex < routeSteps.count {
                updateNextTurn(from: location)
            }
        }
    }
    
    private func checkForHapticFeedback(currentStep: MKRoute.Step, distanceToTurn: CLLocationDistance) {
        let leadDistance = settings.leadTime.distance
        
        // Only send haptic feedback if we're within the lead distance
        guard distanceToTurn <= leadDistance + 20 && distanceToTurn > 0 else { return }
        
        let command = getHapticCommand(from: currentStep.instructions)
        
        // Avoid sending duplicate commands too frequently
        if let lastCommand = lastHapticCommandSent,
           let lastSentTime = hapticCommandSentAt,
           lastCommand == command,
           Date().timeIntervalSince(lastSentTime) < 5 {
            return
        }
        
        bluetoothManager.sendHapticCommand(command)
        lastHapticCommandSent = command
        hapticCommandSentAt = Date()
    }
    
    private func getHapticCommand(from instructions: String) -> HapticCommand {
        let lowercased = instructions.lowercased()
        
        if lowercased.contains("left") || lowercased.contains("turn left") {
            return .left
        } else if lowercased.contains("right") || lowercased.contains("turn right") {
            return .right
        } else if lowercased.contains("straight") || lowercased.contains("continue") {
            return .straight
        } else if lowercased.contains("arrive") || lowercased.contains("destination") {
            return .arrived
        }
        
        return .straight // Default for unclear instructions
    }
}

// MARK: - CLLocationManagerDelegate
extension NavigationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        
        if navigationState == .navigating {
            updateNextTurn(from: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        currentHeading = newHeading.trueHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}