//
//  NavigationView.swift
//  GloveGuide
//
//  Created by Mohammad Adnaan on 2025-10-26.
//

import SwiftUI
import MapKit

struct NavigationView: View {
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
            
            VStack {
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
    
    private var navigationManager: NavigationManager {
        coordinator.navigationManager
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Main info row
            HStack(spacing: 20) {
                // ETA
                VStack(alignment: .leading) {
                    Text("ETA")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatETA(navigationManager.estimatedTimeOfArrival))
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Divider()
                    .frame(height: 40)
                
                // Time remaining
                VStack(alignment: .leading) {
                    Text("Time Left")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDuration(navigationManager.remainingTime))
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Divider()
                    .frame(height: 40)
                
                // Distance remaining
                VStack(alignment: .leading) {
                    Text("Distance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDistance(navigationManager.remainingDistance))
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
            
            // Connection status and stop button row
            HStack {
                // Bluetooth status
                if coordinator.bluetoothManager.isConnected {
                    HStack(spacing: 6) {
                        Image(systemName: "bluetooth")
                            .foregroundColor(.blue)
                        Text("Connected")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "bluetooth.slash")
                            .foregroundColor(.orange)
                        Text("Disconnected")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // Stop navigation button
                Button(action: {
                    coordinator.showingEndNavigation = true
                }) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Stop Navigation")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .cornerRadius(25)
                }
            }
        }
        .padding(20)
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
            return "\(minutes)m"
        }
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        return formatter.string(fromDistance: distance)
    }
}

#Preview {
    NavigationView(coordinator: AppCoordinator())
}