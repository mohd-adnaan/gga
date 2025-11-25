//
//  SettingsView.swift
//  GloveGuide
//
//  RIGHT GLOVE - DUAL MOTOR - FIXED UI
//

import SwiftUI
import CoreBluetooth

struct SettingsView: View {
    @ObservedObject var coordinator: AppCoordinator
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDeviceList = false
    @State private var testActive = false
    
    private var bluetoothManager: BluetoothManager {
        coordinator.bluetoothManager
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Bluetooth Connection Section
                Section("Bluetooth Connection") {
                    HStack {
                        Image(systemName: bluetoothManager.isConnected ? "hand.point.right.fill" : "hand.point.right")
                            .foregroundColor(bluetoothManager.isConnected ? .green : .gray)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Right Glove")
                                .font(.headline)
                            Text(bluetoothManager.connectionStatus)
                                .font(.caption)
                                .foregroundColor(bluetoothManager.isConnected ? .green : .secondary)
                        }
                        
                        Spacer()
                        
                        Circle()
                            .fill(bluetoothManager.isConnected ? Color.green : Color.gray)
                            .frame(width: 12, height: 12)
                    }
                    .padding(.vertical, 4)
                    
                    // Connection Button
                    if bluetoothManager.isConnected {
                        Button("Disconnect") {
                            bluetoothManager.disconnect()
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                    } else {
                        Button("Scan for Glove") {
                            showingDeviceList = true
                        }
                        .frame(maxWidth: .infinity)
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
                
                // Manual Test Controls
                if bluetoothManager.isConnected {
                    Section(header: Text("Manual Test Controls"),
                            footer: Text("Press once to start vibration, press again to stop.")) {
                        
                        VStack(spacing: 16) {
                            Button(action: {
                                if testActive {
                                    bluetoothManager.testOff()
                                    testActive = false
                                } else {
                                    bluetoothManager.testOn()
                                    testActive = true
                                }
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "hand.point.right.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(testActive ? "STOP GLOVE" : "TEST GLOVE")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text(testActive ? "Tap to stop" : "Tap to vibrate")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    
                                    Spacer()
                                    
                                    if testActive {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    }
                                }
                                .padding(20)
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: testActive ?
                                            [Color.orange, Color.orange.opacity(0.8)] :
                                            [Color.green, Color.green.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Haptic Settings - FIXED SEGMENTED CONTROL
                Section(header: Text("Haptic Settings"),
                        footer: Text("Use 2 motors for stronger vibration feedback.")) {
                    
                    // Motor Count Picker - FIXED
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Number of Motors")
                            .font(.headline)
                        
                        HStack(spacing: 0) {
                            // 1 Motor Button
                            Button(action: {
                                coordinator.settings.motorCount = 1
                                if bluetoothManager.isConnected {
                                    bluetoothManager.setMotorCount(1)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "circle.fill")
                                        .font(.caption)
                                    Text("1 Motor")
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(coordinator.settings.motorCount == 1 ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(coordinator.settings.motorCount == 1 ? Color.blue : Color(.systemGray5))
                                .cornerRadius(8, corners: [.topLeft, .bottomLeft])
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // 2 Motors Button
                            Button(action: {
                                coordinator.settings.motorCount = 2
                                if bluetoothManager.isConnected {
                                    bluetoothManager.setMotorCount(2)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "circle.fill")
                                        .font(.caption)
                                    Image(systemName: "circle.fill")
                                        .font(.caption)
                                    Text("2 Motors")
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(coordinator.settings.motorCount == 2 ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(coordinator.settings.motorCount == 2 ? Color.blue : Color(.systemGray5))
                                .cornerRadius(8, corners: [.topRight, .bottomRight])
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Visual indicator - FIXED
                    HStack {
                        Text("Current Setting:")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        Spacer()
                        HStack(spacing: 6) {
                            ForEach(0..<coordinator.settings.motorCount, id: \.self) { _ in
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 10, height: 10)
                            }
                            Text("\(coordinator.settings.motorCount) motor\(coordinator.settings.motorCount > 1 ? "s" : "") active")
                                .font(.subheadline)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    Picker("Lead Time Before Turn", selection: $coordinator.settings.leadTime) {
                        ForEach(LeadTime.allCases, id: \.self) { leadTime in
                            Text(leadTime.displayName).tag(leadTime)
                        }
                    }
                }
                
                // Navigation Preferences
                Section("Navigation Preferences") {
                    Picker("Default Transport Mode", selection: $coordinator.settings.transportMode) {
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
                    
                    HStack {
                        Text("Configuration")
                        Spacer()
                        Text("Right Glove (Dual Motors)")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Stop any active tests
                        if testActive {
                            bluetoothManager.testOff()
                            testActive = false
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingDeviceList) {
            DeviceListView(bluetoothManager: bluetoothManager)
        }
        .onAppear {
            // Sync motor count when settings open
            if bluetoothManager.isConnected {
                bluetoothManager.setMotorCount(coordinator.settings.motorCount)
            }
        }
    }
}

// Helper extension for rounded corners on specific sides
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct DeviceListView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @Environment(\.presentationMode) var presentationMode
    @State private var isScanning = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Connection Status Banner
                if bluetoothManager.isConnected {
                    VStack(spacing: 8) {
                        HStack(spacing: 16) {
                            HStack(spacing: 6) {
                                Image(systemName: "hand.point.right.fill")
                                    .foregroundColor(.green)
                                Text("Right Glove Connected")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                }
                
                if bluetoothManager.discoveredDevices.isEmpty && !isScanning {
                    emptyStateView
                } else {
                    deviceListContent
                }
            }
            .navigationTitle("BLE Devices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        bluetoothManager.stopScanning()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isScanning ? "Stop" : "Scan") {
                        if isScanning {
                            stopScanning()
                        } else {
                            startScanning()
                        }
                    }
                }
            }
        }
        .onAppear {
            startScanning()
        }
        .onDisappear {
            bluetoothManager.stopScanning()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No devices found")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Make sure your ESP32 is powered on and in range.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Start Scanning") {
                startScanning()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var deviceListContent: some View {
        List {
            if isScanning {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Scanning for BLE devices...")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("\(bluetoothManager.discoveredDevices.count) device(s) found")) {
                ForEach(bluetoothManager.discoveredDevices, id: \.identifier) { device in
                    DeviceRow(
                        device: device,
                        isTarget: device.name?.contains("GloveGuide") ?? false
                    ) {
                        bluetoothManager.connect(to: device)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private func startScanning() {
        isScanning = true
        bluetoothManager.startScanning()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
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
    let isTarget: Bool
    let onConnect: () -> Void
    
    var body: some View {
        Button(action: onConnect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(device.name ?? "Unknown Device")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if isTarget {
                            Text("🎯")
                                .font(.title3)
                        }
                    }
                    
                    Text(device.identifier.uuidString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
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
