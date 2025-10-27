//
//  HomeView.swift
//  GloveGuide
//
//  Created by Mohammad Adnaan on 2025-10-26.
//

import SwiftUI
import MapKit

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
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map View
                Map(coordinateRegion: $region,
                    showsUserLocation: true,
                    userTrackingMode: .constant(.none))
                    .ignoresSafeArea(edges: .bottom)
                
                VStack {
                    // Top Controls
                    VStack(spacing: 16) {
                        // Search Bar
                        HStack {
                            Button(action: {
                                showingSearchSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.gray)
                                    Text(searchText.isEmpty ? "Search destinations..." : searchText)
                                        .foregroundColor(searchText.isEmpty ? .gray : .primary)
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(radius: 2)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                coordinator.showingSettings = true
                            }) {
                                Image(systemName: "gear")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(radius: 2)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Transport Mode Selector
                        TransportModeSelector(selectedMode: $coordinator.settings.transportMode)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    Spacer()
                    
                    // Connection Status
                    if coordinator.bluetoothManager.isConnected {
                        HStack {
                            Image(systemName: "bluetooth")
                                .foregroundColor(.blue)
                            Text("Connected to \(coordinator.bluetoothManager.connectedDevice?.name ?? "Device")")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    } else {
                        HStack {
                            Image(systemName: "bluetooth.slash")
                                .foregroundColor(.orange)
                            Text("Not connected")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
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
        .onAppear {
            updateRegionToCurrentLocation()
        }
    }
    
    private func updateRegionToCurrentLocation() {
        if let location = coordinator.navigationManager.currentLocation {
            region.center = location.coordinate
        }
    }
}

struct TransportModeSelector: View {
    @Binding var selectedMode: TransportMode
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(TransportMode.allCases, id: \.self) { mode in
                Button(action: {
                    selectedMode = mode
                }) {
                    HStack {
                        Image(systemName: mode.systemImage)
                        Text(mode.displayName)
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(selectedMode == mode ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(selectedMode == mode ? Color.blue : Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: selectedMode == mode ? 3 : 1)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

#Preview {
    HomeView(coordinator: AppCoordinator())
}