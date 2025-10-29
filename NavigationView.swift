//
//  NavigationView.swift
//  GloveGuide
//
//  Created by Mohammad Adnaan on 2025-10-26.
//

import SwiftUI
import MapKit

struct NavigationActiveView: View {
    @ObservedObject var coordinator: AppCoordinator
    @State private var region = MKCoordinateRegion()
    
    var body: some View {
        ZStack {
            // Full-screen map
            NavigationMapView(
                coordinator: coordinator,
                region: $region
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Navigation Bar
                navigationBar
                
                Spacer()
                
                // Bottom info panel
                NavigationInfoPanel(coordinator: coordinator)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .shadow(radius: 10)
                    )
                    .padding()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            updateRegionToCurrentLocation()
        }
        .onReceive(coordinator.navigationManager.$currentLocation) { location in
            if let location = location {
                withAnimation(.easeInOut(duration: 0.5)) {
                    region.center = location.coordinate
                }
            }
        }
    }

    // MARK: - Navigation Bar
    private var navigationBar: some View {
        HStack {
            // Back Button
            Button(action: {
                coordinator.endNavigation()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.body)
                        .fontWeight(.semibold)
                    Text("Back")
                        .font(.body)
                }
                .foregroundColor(.blue)
            }
            
            Spacer()
            
            // Logo in center
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
    
    private func updateRegionToCurrentLocation() {
        if let location = coordinator.navigationManager.currentLocation {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
}

struct NavigationMapView: UIViewRepresentable {
    @ObservedObject var coordinator: AppCoordinator
    @Binding var region: MKCoordinateRegion
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading
        mapView.mapType = .standard
        
        // Configure for navigation
        mapView.showsCompass = true
        mapView.showsScale = true
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update route overlay
        if let route = coordinator.navigationManager.currentRoute {
            mapView.removeOverlays(mapView.overlays)
            mapView.addOverlay(route.polyline)
            
            // Remove existing annotations (except user location) and add destination pin
            let userLocation = mapView.annotations.first(where: { $0 is MKUserLocation })
            mapView.removeAnnotations(mapView.annotations)
            
            // Get the destination coordinate (last coordinate of the polyline)
            let pointCount = route.polyline.pointCount
            let points = route.polyline.points()
            let destinationCoordinate = points[pointCount - 1].coordinate
            
            let destinationAnnotation = MKPointAnnotation()
            destinationAnnotation.coordinate = destinationCoordinate
            destinationAnnotation.title = "Destination"
            mapView.addAnnotation(destinationAnnotation)
            
            // Fit the route in view initially
            if mapView.visibleMapRect.isEmpty {
                mapView.setVisibleMapRect(route.polyline.boundingMapRect,
                                        edgePadding: UIEdgeInsets(top: 100, left: 50, bottom: 300, right: 50),
                                        animated: true)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        let parent: NavigationMapView
        
        init(_ parent: NavigationMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Don't customize user location
            if annotation is MKUserLocation {
                return nil
            }
            
            let identifier = "DestinationPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            // Customize the pin to be red
            annotationView?.markerTintColor = .red
            annotationView?.glyphImage = UIImage(systemName: "mappin")
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if overlay is MKPolyline {
                let renderer = MKPolylineRenderer(overlay: overlay)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 6.0
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

struct NavigationInfoPanel: View {
    @ObservedObject var coordinator: AppCoordinator
    @State private var hasStartedNavigation = false
    
    private var navigationManager: NavigationManager {
        coordinator.navigationManager
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if !hasStartedNavigation {
                // BEFORE STARTING: Show transport mode selector and GO button
                VStack(spacing: 16) {
                    // Transport Mode Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Your Mode")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            // Walking Mode
                            TransportModeButton(
                                icon: "figure.walk",
                                title: "Walking",
                                isSelected: coordinator.settings.transportMode == .walking
                            ) {
                                coordinator.settings.transportMode = .walking
                            }
                            
                            // Cycling Mode
                            TransportModeButton(
                                icon: "bicycle",
                                title: "Cycling",
                                isSelected: coordinator.settings.transportMode == .cycling
                            ) {
                                coordinator.settings.transportMode = .cycling
                            }
                        }
                    }
                    
                    // Connection Status
                    HStack(spacing: 6) {
                        Image(systemName: coordinator.bluetoothManager.isConnected ? "bluetooth" : "bluetooth.slash")
                            .foregroundColor(coordinator.bluetoothManager.isConnected ? .blue : .orange)
                        Text(coordinator.bluetoothManager.isConnected ? "Glove Connected" : "Glove Disconnected")
                            .font(.caption)
                            .foregroundColor(coordinator.bluetoothManager.isConnected ? .blue : .orange)
                    }
                    
                    // GO Button
                    Button(action: {
                        withAnimation {
                            hasStartedNavigation = true
                            coordinator.navigationManager.startNavigation()
                        }
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("START NAVIGATION")
                                .fontWeight(.bold)
                        }
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(20)
                
            } else {
                // AFTER STARTING: Show navigation stats and stop button
                VStack(spacing: 16) {
                    // Navigation Stats in Cards
                    HStack(spacing: 12) {
                        // ETA Card
                        NavigationStatCard(
                            icon: "clock.fill",
                            label: "ETA",
                            value: formatETA(navigationManager.estimatedTimeOfArrival),
                            color: .blue
                        )
                        
                        // Time Left Card
                        NavigationStatCard(
                            icon: "hourglass",
                            label: "Time Left",
                            value: formatDuration(navigationManager.remainingTime),
                            color: .orange
                        )
                        
                        // Distance Card
                        NavigationStatCard(
                            icon: "location.fill",
                            label: "Distance",
                            value: formatDistance(navigationManager.remainingDistance),
                            color: .green
                        )
                    }
                    
                    // Connection Status
                    HStack(spacing: 6) {
                        Image(systemName: coordinator.bluetoothManager.isConnected ? "bluetooth" : "bluetooth.slash")
                            .foregroundColor(coordinator.bluetoothManager.isConnected ? .blue : .orange)
                        Text(coordinator.bluetoothManager.isConnected ? "Glove Connected" : "Glove Disconnected")
                            .font(.caption)
                            .foregroundColor(coordinator.bluetoothManager.isConnected ? .blue : .orange)
                    }
                    
                    // Stop Navigation Button
                    Button(action: {
                        coordinator.showingEndNavigation = true
                    }) {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text("STOP NAVIGATION")
                                .fontWeight(.bold)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(20)
            }
        }
    }
    
    private func formatETA(_ eta: Date?) -> String {
        guard let eta = eta else { return "--:--" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: eta)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        return formatter.string(fromDistance: distance)
    }
}

// MARK: - Transport Mode Button
struct TransportModeButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
                    .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Navigation Stat Card
struct NavigationStatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    NavigationActiveView(coordinator: AppCoordinator())
}
