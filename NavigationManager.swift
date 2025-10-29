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
    @Published var isLocationPermissionGranted = false
    
    // MARK: - Private Properties
    private let _locationManager = CLLocationManager()
    
    // Public access to location manager for permission checking
    var locationManager: CLLocationManager {
        return _locationManager
    }
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
        _locationManager.delegate = self
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Check initial authorization status
        updateLocationPermissionStatus()
        
        switch _locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            _locationManager.startUpdatingLocation()
            _locationManager.startUpdatingHeading()
        case .notDetermined:
            _locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("Location access denied or restricted")
        @unknown default:
            break
        }
    }
    
    private func updateLocationPermissionStatus() {
        DispatchQueue.main.async {
            let status = self._locationManager.authorizationStatus
            print("🔍 Current permission status: \(self.statusString(for: status))")
            
            // Only consider authorizedWhenInUse and authorizedAlways as valid for continuous location access
            // Note: "When I Share" is not sufficient for navigation apps
            let hasProperPermission = status == .authorizedWhenInUse || status == .authorizedAlways
            
            self.isLocationPermissionGranted = hasProperPermission
            
            print("🔍 Permission granted: \(self.isLocationPermissionGranted)")
            
            // If we don't have proper permission, stop any existing location updates
            if !hasProperPermission {
                self._locationManager.stopUpdatingLocation()
                self._locationManager.stopUpdatingHeading()
            }
        }
    }
    
    private func statusString(for status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Authorized Always"
        case .authorizedWhenInUse: return "Authorized When In Use"
        @unknown default: return "Unknown"
        }
    }
    
    func requestLocationPermission() {
        print("🔍 Requesting location permission, current status: \(statusString(for: _locationManager.authorizationStatus))")
        DispatchQueue.main.async {
            self._locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func checkCurrentPermissionStatus() {
        print("🔄 Checking current permission status")
        updateLocationPermissionStatus()
        
        // If we have permission, try to start location updates
        if isLocationPermissionGranted {
            _locationManager.startUpdatingLocation()
            _locationManager.startUpdatingHeading()
        }
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
        case .driving:
            request.transportType = .automobile
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
        _locationManager.startUpdatingLocation()
        _locationManager.startUpdatingHeading()
    }
    
    func stopNavigation() {
        navigationState = .idle
        currentRoute = nil
        routeSteps = []
        currentStepIndex = 0
        bluetoothManager.sendHapticCommand(.stop)
        _locationManager.stopUpdatingLocation()
        _locationManager.stopUpdatingHeading()
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
        
        print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        DispatchQueue.main.async {
            self.currentLocation = location
            
            if self.navigationState == .navigating {
                self.updateNextTurn(from: location)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.currentHeading = newHeading.trueHeading
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("🔍 Location authorization changed to: \(statusString(for: manager.authorizationStatus))")
        
        DispatchQueue.main.async {
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                print("✅ Location permission granted, starting updates")
                manager.startUpdatingLocation()
                manager.startUpdatingHeading()
                self.isLocationPermissionGranted = true
                
                // Get immediate location if available
                if let location = manager.location {
                    self.currentLocation = location
                }
                
            case .denied, .restricted:
                print("❌ Location access denied or restricted")
                manager.stopUpdatingLocation()
                manager.stopUpdatingHeading()
                self.isLocationPermissionGranted = false
                
            case .notDetermined:
                print("❓ Location permission not determined")
                self.isLocationPermissionGranted = false
                
            @unknown default:
                print("❓ Unknown location authorization status")
                self.isLocationPermissionGranted = false
            }
        }
    }
}