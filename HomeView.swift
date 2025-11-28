//
//  HomeView.swift
//  GloveGuide
//
//

import SwiftUI
import MapKit
import Combine
import CoreBluetooth
import UIKit
import CoreLocation

struct HomeView: View {
    @ObservedObject var coordinator: AppCoordinator
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var showingSearchSheet = false
    @State private var showingSideMenu = false
    @StateObject private var locationManager = LocationPermissionManager()
    
    var body: some View {
        ZStack {
            // Map View
            mapView
            
            // Main Content
            VStack(spacing: 0) {
                // Top Navigation Header
                navigationHeader
                
                Spacer()
                
                // Bottom Search Bar
                bottomSearchBar
                    .padding(.bottom, 20)
            }
            
            // Location permission overlay
            if !locationManager.hasPermission {
                locationPermissionOverlay
            }
            
            // Side Menu
            SideMenuView(isShowing: $showingSideMenu)
        }
        .background(Color(.systemBackground))
        .edgesIgnoringSafeArea(.bottom)
        .sheet(isPresented: $showingSearchSheet) {
            SearchView(
                coordinator: coordinator,
                searchText: $searchText,
                searchResults: $searchResults,
                isSearching: $isSearching
            )
        }
        .sheet(isPresented: $coordinator.showingSettings) {
            SettingsView(coordinator: coordinator)
        }
        .onReceive(locationManager.$currentLocation) { location in
            if let location = location {
                // Optional: Only update region if user hasn't moved map recently
                // For now we keep existing behavior
                withAnimation(.easeInOut(duration: 1.0)) {
                    region.center = location.coordinate
                }
                coordinator.navigationManager.currentLocation = location
            }
        }
    }

    // ... [navigationHeader, bottomSearchBar, connectionStatusBadge, locationPermissionOverlay remain unchanged] ...
    private var navigationHeader: some View {
        HStack {
            // Menu Button
            Button(action: {
                withAnimation {
                    showingSideMenu.toggle()
                }
            }) {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // Logo
            Image("logo-glove-guide-home")
                .resizable()
                .scaledToFit()
                .frame(height: 35)
            
            Spacer()
            
            // Settings Button
            Button(action: {
                coordinator.showingSettings = true
            }) {
                Image(systemName: "gear")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.top)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Bottom Search Bar
    private var bottomSearchBar: some View {
        VStack(spacing: 12) {
            // Single Glove Connection Status
            connectionStatusBadge
            
            // Search Button
            Button(action: {
                showingSearchSheet = true
            }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    Text(searchText.isEmpty ? "Search Here" : searchText)
                        .foregroundColor(searchText.isEmpty ? .gray : .primary)
                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
    }
    
    private var connectionStatusBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: coordinator.bluetoothManager.isConnected ?
                "hand.point.right.fill" : "hand.point.right")
                .font(.caption)
                .foregroundColor(coordinator.bluetoothManager.isConnected ? .green : .gray)
            
            Text(coordinator.bluetoothManager.isConnected ? "Right Glove Connected" : "Glove Disconnected")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(coordinator.bluetoothManager.isConnected ? .green : .gray)
            
            if coordinator.bluetoothManager.isConnected {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(coordinator.bluetoothManager.isConnected ?
                    Color.green.opacity(0.1) : Color.gray.opacity(0.1))
        )
    }
    
    private var locationPermissionOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image(systemName: "location.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Allow Location Access")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("GloveGuide needs your location to show your position and provide navigation.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 50)
                
                VStack(spacing: 15) {
                    Button("Allow Location Access") {
                        locationManager.requestPermission()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    
                    if locationManager.isDenied {
                        Button("Open Settings") {
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 50)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
                    .shadow(radius: 10)
            )
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Updated Map View
    private var mapView: some View {
        // Replaced SwiftUI Map with custom MKMapView wrapper to support Long Press
        HomeMapView(coordinator: coordinator, region: $region)
            .ignoresSafeArea(.all)
    }
}

// ... [LocationPermissionManager class remains unchanged] ...
// Dedicated location permission manager
class LocationPermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var hasPermission = false
    @Published var currentLocation: CLLocation?
    @Published var isDenied = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkInitialPermission()
    }
    
    private func checkInitialPermission() {
        let status = locationManager.authorizationStatus
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            hasPermission = true
            isDenied = false
            startLocationUpdates()
        case .denied, .restricted:
            hasPermission = false
            isDenied = true
        case .notDetermined:
            hasPermission = false
            isDenied = false
        @unknown default:
            hasPermission = false
            isDenied = false
        }
    }
    
    func requestPermission() {
        print("🔥 REQUESTING LOCATION PERMISSION")
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func startLocationUpdates() {
        print("🔥 STARTING LOCATION UPDATES")
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            DispatchQueue.main.async {
                self.currentLocation = location
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.hasPermission = true
                self.isDenied = false
                self.startLocationUpdates()
            case .denied, .restricted:
                self.hasPermission = false
                self.isDenied = true
                manager.stopUpdatingLocation()
            case .notDetermined:
                self.hasPermission = false
                self.isDenied = false
            @unknown default:
                self.hasPermission = false
                self.isDenied = false
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("🔥 LOCATION ERROR: \(error)")
    }
}

// MARK: - HomeMapView (UIViewRepresentable)
struct HomeMapView: UIViewRepresentable {
    @ObservedObject var coordinator: AppCoordinator
    @Binding var region: MKCoordinateRegion

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow // Follow user initially
        
        // Add Long Press Gesture
        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5 // Require hold to avoid accidental drops while scrolling
        mapView.addGestureRecognizer(longPress)
        
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // We let the map handle its own region updates mostly, but if we wanted to enforce
        // the external binding we could do:
        // mapView.setRegion(region, animated: true)
        // However, this often conflicts with user scrolling, so we usually leave it
        // unless a specific event triggers a center.
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: HomeMapView

        init(_ parent: HomeMapView) {
            self.parent = parent
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            // Only trigger on the start of the gesture
            if gesture.state == .began {
                let mapView = gesture.view as! MKMapView
                let point = gesture.location(in: mapView)
                let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
                
                // Haptic feedback to confirm drop
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                // 1. Add Visual Pin
                mapView.removeAnnotations(mapView.annotations) // Clear previous
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = "Dropped Pin"
                mapView.addAnnotation(annotation)
                
                // 2. Prepare Destination
                let placemark = MKPlacemark(coordinate: coordinate)
                let mapItem = MKMapItem(placemark: placemark)
                mapItem.name = "Dropped Pin"
                
                // 3. Start Navigation Flow
                // This triggers calculation and switches screen to NavigationActiveView
                parent.coordinator.startNavigation(to: mapItem)
            }
        }
    }
}

#Preview {
    HomeView(coordinator: AppCoordinator())
}






////
////  HomeView.swift
////  GloveGuide
////
////  Simplified - RIGHT GLOVE ONLY
////
//
//import SwiftUI
//import MapKit
//import Combine
//import CoreBluetooth
//import UIKit
//import CoreLocation
//
//struct HomeView: View {
//    @ObservedObject var coordinator: AppCoordinator
//    @State private var searchText = ""
//    @State private var searchResults: [MKMapItem] = []
//    @State private var isSearching = false
//    @State private var region = MKCoordinateRegion(
//        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
//        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
//    )
//    @State private var showingSearchSheet = false
//    @State private var showingSideMenu = false
//    @StateObject private var locationManager = LocationPermissionManager()
//    
//    var body: some View {
//        ZStack {
//            // Map View
//            mapView
//            
//            // Main Content
//            VStack(spacing: 0) {
//                // Top Navigation Header
//                navigationHeader
//                
//                Spacer()
//                
//                // Bottom Search Bar
//                bottomSearchBar
//                    .padding(.bottom, 20)
//            }
//            
//            // Location permission overlay
//            if !locationManager.hasPermission {
//                locationPermissionOverlay
//            }
//            
//            // Side Menu
//            SideMenuView(isShowing: $showingSideMenu)
//        }
//        .background(Color(.systemBackground))
//        .edgesIgnoringSafeArea(.bottom)
//        .sheet(isPresented: $showingSearchSheet) {
//            SearchView(
//                coordinator: coordinator,
//                searchText: $searchText,
//                searchResults: $searchResults,
//                isSearching: $isSearching
//            )
//        }
//        .sheet(isPresented: $coordinator.showingSettings) {
//            SettingsView(coordinator: coordinator)
//        }
//        .onReceive(locationManager.$currentLocation) { location in
//            if let location = location {
//                withAnimation(.easeInOut(duration: 1.0)) {
//                    region.center = location.coordinate
//                }
//                coordinator.navigationManager.currentLocation = location
//            }
//        }
//    }
//
//    // MARK: - Navigation Header
//    private var navigationHeader: some View {
//        HStack {
//            // Menu Button
//            Button(action: {
//                withAnimation {
//                    showingSideMenu.toggle()
//                }
//            }) {
//                Image(systemName: "line.3.horizontal")
//                    .font(.title2)
//                    .foregroundColor(.primary)
//                    .frame(width: 44, height: 44)
//            }
//            
//            Spacer()
//            
//            // Logo
//            Image("logo-glove-guide-home")
//                .resizable()
//                .scaledToFit()
//                .frame(height: 35)
//            
//            Spacer()
//            
//            // Settings Button
//            Button(action: {
//                coordinator.showingSettings = true
//            }) {
//                Image(systemName: "gear")
//                    .font(.title2)
//                    .foregroundColor(.primary)
//                    .frame(width: 44, height: 44)
//            }
//        }
//        .padding(.horizontal, 16)
//        .padding(.vertical, 8)
//        .background(
//            Color(.systemBackground)
//                .edgesIgnoringSafeArea(.top)
//        )
//        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
//    }
//    
//    // MARK: - Bottom Search Bar
//    private var bottomSearchBar: some View {
//        VStack(spacing: 12) {
//            // Single Glove Connection Status
//            connectionStatusBadge
//            
//            // Search Button
//            Button(action: {
//                showingSearchSheet = true
//            }) {
//                HStack {
//                    Image(systemName: "magnifyingglass")
//                        .foregroundColor(.gray)
//                    Text(searchText.isEmpty ? "Search Here" : searchText)
//                        .foregroundColor(searchText.isEmpty ? .gray : .primary)
//                    Spacer()
//                }
//                .padding()
//                .background(Color(.systemBackground))
//                .cornerRadius(16)
//                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
//            }
//            .buttonStyle(PlainButtonStyle())
//        }
//        .padding(.horizontal, 16)
//    }
//    
//    private var connectionStatusBadge: some View {
//        HStack(spacing: 8) {
//            Image(systemName: coordinator.bluetoothManager.isConnected ?
//                "hand.point.right.fill" : "hand.point.right")
//                .font(.caption)
//                .foregroundColor(coordinator.bluetoothManager.isConnected ? .green : .gray)
//            
//            Text(coordinator.bluetoothManager.isConnected ? "Right Glove Connected" : "Glove Disconnected")
//                .font(.caption)
//                .fontWeight(.medium)
//                .foregroundColor(coordinator.bluetoothManager.isConnected ? .green : .gray)
//            
//            if coordinator.bluetoothManager.isConnected {
//                Circle()
//                    .fill(Color.green)
//                    .frame(width: 8, height: 8)
//            }
//        }
//        .padding(.horizontal, 16)
//        .padding(.vertical, 8)
//        .background(
//            Capsule()
//                .fill(coordinator.bluetoothManager.isConnected ?
//                    Color.green.opacity(0.1) : Color.gray.opacity(0.1))
//        )
//    }
//    
//    private var locationPermissionOverlay: some View {
//        ZStack {
//            Color.black.opacity(0.7)
//                .ignoresSafeArea()
//            
//            VStack(spacing: 30) {
//                Image(systemName: "location.circle")
//                    .font(.system(size: 60))
//                    .foregroundColor(.blue)
//                
//                Text("Allow Location Access")
//                    .font(.title2)
//                    .fontWeight(.semibold)
//                
//                Text("GloveGuide needs your location to show your position and provide navigation.")
//                    .multilineTextAlignment(.center)
//                    .foregroundColor(.secondary)
//                    .padding(.horizontal, 50)
//                
//                VStack(spacing: 15) {
//                    Button("Allow Location Access") {
//                        locationManager.requestPermission()
//                    }
//                    .font(.headline)
//                    .foregroundColor(.white)
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .background(Color.blue)
//                    .cornerRadius(12)
//                    
//                    if locationManager.isDenied {
//                        Button("Open Settings") {
//                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
//                                UIApplication.shared.open(settingsUrl)
//                            }
//                        }
//                        .font(.subheadline)
//                        .foregroundColor(.blue)
//                    }
//                }
//                .padding(.horizontal, 50)
//            }
//            .padding()
//            .background(
//                RoundedRectangle(cornerRadius: 20)
//                    .fill(.regularMaterial)
//                    .shadow(radius: 10)
//            )
//            .padding(.horizontal, 40)
//        }
//    }
//    
//    private var mapView: some View {
//        Map(coordinateRegion: $region, showsUserLocation: true, userTrackingMode: .constant(.none))
//            .ignoresSafeArea(.all)
//    }
//}
//
//// Dedicated location permission manager
//class LocationPermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
//    private let locationManager = CLLocationManager()
//    
//    @Published var hasPermission = false
//    @Published var currentLocation: CLLocation?
//    @Published var isDenied = false
//    
//    override init() {
//        super.init()
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        checkInitialPermission()
//    }
//    
//    private func checkInitialPermission() {
//        let status = locationManager.authorizationStatus
//        switch status {
//        case .authorizedWhenInUse, .authorizedAlways:
//            hasPermission = true
//            isDenied = false
//            startLocationUpdates()
//        case .denied, .restricted:
//            hasPermission = false
//            isDenied = true
//        case .notDetermined:
//            hasPermission = false
//            isDenied = false
//        @unknown default:
//            hasPermission = false
//            isDenied = false
//        }
//    }
//    
//    func requestPermission() {
//        print("🔥 REQUESTING LOCATION PERMISSION")
//        locationManager.requestWhenInUseAuthorization()
//    }
//    
//    private func startLocationUpdates() {
//        print("🔥 STARTING LOCATION UPDATES")
//        locationManager.startUpdatingLocation()
//        locationManager.startUpdatingHeading()
//    }
//    
//    // MARK: - CLLocationManagerDelegate
//    
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        if let location = locations.last {
//            DispatchQueue.main.async {
//                self.currentLocation = location
//            }
//        }
//    }
//    
//    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
//        DispatchQueue.main.async {
//            switch manager.authorizationStatus {
//            case .authorizedWhenInUse, .authorizedAlways:
//                self.hasPermission = true
//                self.isDenied = false
//                self.startLocationUpdates()
//            case .denied, .restricted:
//                self.hasPermission = false
//                self.isDenied = true
//                manager.stopUpdatingLocation()
//            case .notDetermined:
//                self.hasPermission = false
//                self.isDenied = false
//            @unknown default:
//                self.hasPermission = false
//                self.isDenied = false
//            }
//        }
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        print("🔥 LOCATION ERROR: \(error)")
//    }
//}
//
//#Preview {
//    HomeView(coordinator: AppCoordinator())
//}
