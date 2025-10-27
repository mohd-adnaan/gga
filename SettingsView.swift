//
//  SettingsView.swift
//  GloveGuide
//
//  Created by Mohammad Adnaan on 2025-10-26.
//

import SwiftUI
import CoreBluetooth

struct SettingsView: View {
    @ObservedObject var coordinator: AppCoordinator
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDeviceList = false
    
    private var settings: AppSettings {
        coordinator.settings
    }
    
    private var bluetoothManager: BluetoothManager {
        coordinator.bluetoothManager
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Haptic Settings Section
                Section("Haptic Settings") {
                    // Vibration Intensity
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Vibration Intensity")
                            Spacer()
                            Text("\(Int(settings.vibrationIntensity))%")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $settings.vibrationIntensity, in: 0...100, step: 5)
                            .accentColor(.blue)
                    }
                    
                    // Lead Time
                    Picker("Lead Time Before Turn", selection: $settings.leadTime) {
                        ForEach(LeadTime.allCases, id: \.self) { leadTime in
                            Text(leadTime.displayName).tag(leadTime)
                        }
                    }
                    
                    // Progressive Intensity
                    Toggle("Progressive Intensity", isOn: $settings.progressiveIntensityEnabled)
                }
                
                // Bluetooth Connection Section
                Section("Bluetooth Connection") {
                    HStack {
                        Image(systemName: bluetoothManager.isConnected ? "bluetooth" : "bluetooth.slash")
                            .foregroundColor(bluetoothManager.isConnected ? .blue : .gray)
                        
                        VStack(alignment: .leading) {
                            Text("Device Status")
                                .font(.headline)
                            Text(bluetoothManager.connectionStatus)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if bluetoothManager.isConnected {
                            Button("Disconnect") {
                                bluetoothManager.disconnect()
                            }
                            .foregroundColor(.red)
                        } else {
                            Button("Connect") {
                                showingDeviceList = true
                            }
                        }
                    }
                    
                    if bluetoothManager.isConnected,
                       let deviceName = bluetoothManager.connectedDevice?.name {
                        HStack {
                            Text("Connected Device")
                            Spacer()
                            Text(deviceName)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Navigation Preferences Section
                Section("Navigation Preferences") {
                    Picker("Default Transport Mode", selection: $settings.transportMode) {
                        ForEach(TransportMode.allCases, id: \.self) { mode in
                            HStack {
                                Image(systemName: mode.systemImage)
                                Text(mode.displayName)
                            }
                            .tag(mode)
                        }
                    }
                }
                
                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("App Name")
                        Spacer()
                        Text("Glove Guide")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    // Sync settings to connected device
                    if bluetoothManager.isConnected {
                        bluetoothManager.syncSettings(
                            intensity: settings.vibrationIntensity,
                            leadTime: settings.leadTime,
                            progressiveEnabled: settings.progressiveIntensityEnabled
                        )
                    }
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .sheet(isPresented: $showingDeviceList) {
            DeviceListView(bluetoothManager: bluetoothManager)
        }
    }
}

struct DeviceListView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @Environment(\.presentationMode) var presentationMode
    @State private var isScanning = false
    
    var body: some View {
        NavigationView {
            VStack {
                if bluetoothManager.discoveredDevices.isEmpty && !isScanning {
                    VStack(spacing: 20) {
                        Image(systemName: "bluetooth")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No devices found")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Make sure your glove device is in pairing mode and try scanning again.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Start Scanning") {
                            startScanning()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        if isScanning {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Scanning for devices...")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        ForEach(bluetoothManager.discoveredDevices, id: \.identifier) { device in
                            DeviceRow(device: device) {
                                bluetoothManager.connect(to: device)
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                    .refreshable {
                        startScanning()
                    }
                }
            }
            .navigationTitle("Available Devices")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    bluetoothManager.stopScanning()
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(isScanning ? "Stop" : "Scan") {
                    if isScanning {
                        stopScanning()
                    } else {
                        startScanning()
                    }
                }
            )
        }
        .onAppear {
            startScanning()
        }
        .onDisappear {
            bluetoothManager.stopScanning()
        }
    }
    
    private func startScanning() {
        isScanning = true
        bluetoothManager.startScanning()
        
        // Stop scanning after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            stopScanning()
        }
    }
    
    private func stopScanning() {
        isScanning = false
        bluetoothManager.stopScanning()
    }
}

struct DeviceRow: View {
    let device: CBPeripheral
    let onConnect: () -> Void
    
    var body: some View {
        Button(action: onConnect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name ?? "Unknown Device")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(device.identifier.uuidString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsView(coordinator: AppCoordinator())
}