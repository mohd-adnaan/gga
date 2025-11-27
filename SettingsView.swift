//
//  SettingsView.swift
//  GloveGuide
//
//  Updated for DUAL GLOVE support (LEFT + RIGHT)
//

import SwiftUI
import CoreBluetooth

struct SettingsView: View {
    @ObservedObject var coordinator: AppCoordinator
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDeviceList = false
    @State private var leftTestActive = false
    @State private var rightTestActive = false
    
    private var bluetoothManager: BluetoothManager {
        coordinator.bluetoothManager
    }
    
    var body: some View {
        NavigationView {
            Form {
                // LEFT GLOVE Section
                Section(header: Text("🫲 Left Glove")) {
                    // Connection Status
                    HStack {
                        Image(systemName: bluetoothManager.leftGloveConnected ? "hand.point.left.fill" : "hand.point.left")
                            .foregroundColor(bluetoothManager.leftGloveConnected ? .green : .gray)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Left Glove")
                                .font(.headline)
                            Text(bluetoothManager.leftGloveStatus)
                                .font(.caption)
                                .foregroundColor(bluetoothManager.leftGloveConnected ? .green : .secondary)
                        }
                        
                        Spacer()
                        
                        Circle()
                            .fill(bluetoothManager.leftGloveConnected ? Color.green : Color.gray)
                            .frame(width: 12, height: 12)
                    }
                    .padding(.vertical, 4)
                    
                    // Connection Button
                    if bluetoothManager.leftGloveConnected {
                        Button("Disconnect Left") {
                            bluetoothManager.disconnect(glove: .left)
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Motor Count for LEFT glove
                    if bluetoothManager.leftGloveConnected {
                        motorCountPicker(
                            title: "Left Glove Motors",
                            motorCount: $coordinator.settings.motorCountLeft,
                            glove: .left
                        )
                        
                        // Test Button for LEFT
                        testButton(
                            glove: .left,
                            isActive: $leftTestActive,
                            action: {
                                if leftTestActive {
                                    bluetoothManager.testOff(glove: .left)
                                    leftTestActive = false
                                } else {
                                    bluetoothManager.testOn(glove: .left)
                                    leftTestActive = true
                                }
                            }
                        )
                    }
                }
                
                // RIGHT GLOVE Section
                Section(header: Text("🫱 Right Glove")) {
                    // Connection Status
                    HStack {
                        Image(systemName: bluetoothManager.rightGloveConnected ? "hand.point.right.fill" : "hand.point.right")
                            .foregroundColor(bluetoothManager.rightGloveConnected ? .green : .gray)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Right Glove")
                                .font(.headline)
                            Text(bluetoothManager.rightGloveStatus)
                                .font(.caption)
                                .foregroundColor(bluetoothManager.rightGloveConnected ? .green : .secondary)
                        }
                        
                        Spacer()
                        
                        Circle()
                            .fill(bluetoothManager.rightGloveConnected ? Color.green : Color.gray)
                            .frame(width: 12, height: 12)
                    }
                    .padding(.vertical, 4)
                    
                    // Connection Button
                    if bluetoothManager.rightGloveConnected {
                        Button("Disconnect Right") {
                            bluetoothManager.disconnect(glove: .right)
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Motor Count for RIGHT glove
                    if bluetoothManager.rightGloveConnected {
                        motorCountPicker(
                            title: "Right Glove Motors",
                            motorCount: $coordinator.settings.motorCountRight,
                            glove: .right
                        )
                        
                        // Test Button for RIGHT
                        testButton(
                            glove: .right,
                            isActive: $rightTestActive,
                            action: {
                                if rightTestActive {
                                    bluetoothManager.testOff(glove: .right)
                                    rightTestActive = false
                                } else {
                                    bluetoothManager.testOn(glove: .right)
                                    rightTestActive = true
                                }
                            }
                        )
                    }
                }
                
                // Scan Button (if neither connected)
                if !bluetoothManager.leftGloveConnected || !bluetoothManager.rightGloveConnected {
                    Section {
                        Button(action: {
                            showingDeviceList = true
                        }) {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                Text("Scan for Gloves")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                // Navigation Preferences
                Section(header: Text("Navigation Preferences"),
                        footer: Text("Lead time determines when you'll feel vibrations before turns.")) {
                    Picker("Lead Time Before Turn", selection: $coordinator.settings.leadTime) {
                        ForEach(LeadTime.allCases, id: \.self) { leadTime in
                            Text(leadTime.displayName).tag(leadTime)
                        }
                    }
                    
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
                        Text("Configuration")
                        Spacer()
                        Text("Dual Gloves (L+R)")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(bluetoothManager.connectionStatus)
                            .foregroundColor(.secondary)
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
                        if leftTestActive {
                            bluetoothManager.testOff(glove: .left)
                            leftTestActive = false
                        }
                        if rightTestActive {
                            bluetoothManager.testOff(glove: .right)
                            rightTestActive = false
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
            // Sync motor counts when settings open
            if bluetoothManager.leftGloveConnected {
                bluetoothManager.setMotorCount(coordinator.settings.motorCountLeft, for: .left)
            }
            if bluetoothManager.rightGloveConnected {
                bluetoothManager.setMotorCount(coordinator.settings.motorCountRight, for: .right)
            }
        }
    }
    
    // MARK: - Motor Count Picker Component
    @ViewBuilder
    private func motorCountPicker(title: String, motorCount: Binding<Int>, glove: GloveSide) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Number of Motors")
                .font(.headline)
            
            HStack(spacing: 0) {
                // 1 Motor Button
                Button(action: {
                    motorCount.wrappedValue = 1
                    bluetoothManager.setMotorCount(1, for: glove)
                }) {
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.caption)
                        Text("1 Motor")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(motorCount.wrappedValue == 1 ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(motorCount.wrappedValue == 1 ? Color.blue : Color(.systemGray5))
                    .cornerRadius(8, corners: [.topLeft, .bottomLeft])
                }
                .buttonStyle(PlainButtonStyle())
                
                // 2 Motors Button
                Button(action: {
                    motorCount.wrappedValue = 2
                    bluetoothManager.setMotorCount(2, for: glove)
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
                    .foregroundColor(motorCount.wrappedValue == 2 ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(motorCount.wrappedValue == 2 ? Color.blue : Color(.systemGray5))
                    .cornerRadius(8, corners: [.topRight, .bottomRight])
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
        
        // Visual indicator
        HStack {
            Text("Current Setting:")
                .foregroundColor(.secondary)
                .font(.subheadline)
            Spacer()
            HStack(spacing: 6) {
                ForEach(0..<motorCount.wrappedValue, id: \.self) { _ in
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                }
                Text("\(motorCount.wrappedValue) motor\(motorCount.wrappedValue > 1 ? "s" : "") active")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Test Button Component
    @ViewBuilder
    private func testButton(glove: GloveSide, isActive: Binding<Bool>, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: glove == .left ? "hand.point.left.fill" : "hand.point.right.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isActive.wrappedValue ? "STOP TEST" : "TEST \(glove.rawValue) GLOVE")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(isActive.wrappedValue ? "Tap to stop" : "Tap to vibrate")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                if isActive.wrappedValue {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: isActive.wrappedValue ?
                        [Color.orange, Color.orange.opacity(0.8)] :
                        [Color.green, Color.green.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 8)
    }
}

// Helper extension for rounded corners
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

// Device List View
struct DeviceListView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @Environment(\.presentationMode) var presentationMode
    @State private var isScanning = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Connection Status Banner
                if bluetoothManager.leftGloveConnected || bluetoothManager.rightGloveConnected {
                    VStack(spacing: 8) {
                        HStack(spacing: 16) {
                            if bluetoothManager.leftGloveConnected {
                                gloveStatusBadge(icon: "hand.point.left.fill", text: "Left Connected")
                            }
                            if bluetoothManager.rightGloveConnected {
                                gloveStatusBadge(icon: "hand.point.right.fill", text: "Right Connected")
                            }
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
            .navigationTitle("Scan for Gloves")
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
    
    private func gloveStatusBadge(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.green)
            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No devices found")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Make sure both ESP32 gloves are powered on and in range.")
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
                        isTarget: device.name?.contains("GloveGuide") ?? false,
                        gloveType: device.name?.contains("LEFT") == true ? .left :
                                   device.name?.contains("RIGHT") == true ? .right : nil
                    ) {
                        bluetoothManager.connect(to: device)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            // Don't dismiss if we might connect more gloves
                            if bluetoothManager.leftGloveConnected && bluetoothManager.rightGloveConnected {
                                presentationMode.wrappedValue.dismiss()
                            }
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
    let gloveType: GloveSide?
    let onConnect: () -> Void
    
    var body: some View {
        Button(action: onConnect) {
            HStack {
                // Glove icon
                if let glove = gloveType {
                    Image(systemName: glove == .left ? "hand.point.left.fill" : "hand.point.right.fill")
                        .foregroundColor(isTarget ? .blue : .gray)
                        .font(.title3)
                }
                
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








////
////  SettingsView.swift
////  GloveGuide
////
//
//import SwiftUI
//import CoreBluetooth
//
//struct SettingsView: View {
//    @ObservedObject var coordinator: AppCoordinator
//    @Environment(\.presentationMode) var presentationMode
//    @State private var showingDeviceList = false
//    @State private var testActive = false
//    
//    private var bluetoothManager: BluetoothManager {
//        coordinator.bluetoothManager
//    }
//    
//    var body: some View {
//        NavigationView {
//            Form {
//                // Bluetooth Connection Section
//                Section("Bluetooth Connection") {
//                    HStack {
//                        Image(systemName: bluetoothManager.isConnected ? "hand.point.right.fill" : "hand.point.right")
//                            .foregroundColor(bluetoothManager.isConnected ? .green : .gray)
//                            .font(.title2)
//                        
//                        VStack(alignment: .leading, spacing: 4) {
//                            Text("Right Glove")
//                                .font(.headline)
//                            Text(bluetoothManager.connectionStatus)
//                                .font(.caption)
//                                .foregroundColor(bluetoothManager.isConnected ? .green : .secondary)
//                        }
//                        
//                        Spacer()
//                        
//                        Circle()
//                            .fill(bluetoothManager.isConnected ? Color.green : Color.gray)
//                            .frame(width: 12, height: 12)
//                    }
//                    .padding(.vertical, 4)
//                    
//                    // Connection Button
//                    if bluetoothManager.isConnected {
//                        Button("Disconnect") {
//                            bluetoothManager.disconnect()
//                        }
//                        .foregroundColor(.red)
//                        .frame(maxWidth: .infinity)
//                    } else {
//                        Button("Scan for Glove") {
//                            showingDeviceList = true
//                        }
//                        .frame(maxWidth: .infinity)
//                    }
//                    
//                    if bluetoothManager.isConnected,
//                       let deviceName = bluetoothManager.connectedDevice?.name {
//                        HStack {
//                            Text("Connected Device")
//                            Spacer()
//                            Text(deviceName)
//                                .foregroundColor(.secondary)
//                        }
//                    }
//                }
//                
//                // Manual Test Controls
//                if bluetoothManager.isConnected {
//                    Section(header: Text("Manual Test Controls"),
//                            footer: Text("Press once to start vibration, press again to stop.")) {
//                        
//                        VStack(spacing: 16) {
//                            Button(action: {
//                                if testActive {
//                                    bluetoothManager.testOff()
//                                    testActive = false
//                                } else {
//                                    bluetoothManager.testOn()
//                                    testActive = true
//                                }
//                            }) {
//                                HStack(spacing: 16) {
//                                    Image(systemName: "hand.point.right.fill")
//                                        .font(.system(size: 32))
//                                        .foregroundColor(.white)
//                                    
//                                    VStack(alignment: .leading, spacing: 4) {
//                                        Text(testActive ? "STOP GLOVE" : "TEST GLOVE")
//                                            .font(.headline)
//                                            .foregroundColor(.white)
//                                        Text(testActive ? "Tap to stop" : "Tap to vibrate")
//                                            .font(.caption)
//                                            .foregroundColor(.white.opacity(0.8))
//                                    }
//                                    
//                                    Spacer()
//                                    
//                                    if testActive {
//                                        ProgressView()
//                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
//                                    }
//                                }
//                                .padding(20)
//                                .frame(maxWidth: .infinity)
//                                .background(
//                                    LinearGradient(
//                                        gradient: Gradient(colors: testActive ?
//                                            [Color.orange, Color.orange.opacity(0.8)] :
//                                            [Color.green, Color.green.opacity(0.8)]),
//                                        startPoint: .leading,
//                                        endPoint: .trailing
//                                    )
//                                )
//                                .cornerRadius(12)
//                            }
//                            .buttonStyle(PlainButtonStyle())
//                        }
//                        .padding(.vertical, 8)
//                    }
//                }
//                
//                // Haptic Settings - FIXED SEGMENTED CONTROL
//                Section(header: Text("Haptic Settings"),
//                        footer: Text("Use 2 motors for stronger vibration feedback.")) {
//                    
//                    // Motor Count Picker - FIXED
//                    VStack(alignment: .leading, spacing: 12) {
//                        Text("Number of Motors")
//                            .font(.headline)
//                        
//                        HStack(spacing: 0) {
//                            // 1 Motor Button
//                            Button(action: {
//                                coordinator.settings.motorCount = 1
//                                if bluetoothManager.isConnected {
//                                    bluetoothManager.setMotorCount(1)
//                                }
//                            }) {
//                                HStack {
//                                    Image(systemName: "circle.fill")
//                                        .font(.caption)
//                                    Text("1 Motor")
//                                }
//                                .font(.subheadline)
//                                .fontWeight(.medium)
//                                .foregroundColor(coordinator.settings.motorCount == 1 ? .white : .primary)
//                                .frame(maxWidth: .infinity)
//                                .padding(.vertical, 12)
//                                .background(coordinator.settings.motorCount == 1 ? Color.blue : Color(.systemGray5))
//                                .cornerRadius(8, corners: [.topLeft, .bottomLeft])
//                            }
//                            .buttonStyle(PlainButtonStyle())
//                            
//                            // 2 Motors Button
//                            Button(action: {
//                                coordinator.settings.motorCount = 2
//                                if bluetoothManager.isConnected {
//                                    bluetoothManager.setMotorCount(2)
//                                }
//                            }) {
//                                HStack(spacing: 4) {
//                                    Image(systemName: "circle.fill")
//                                        .font(.caption)
//                                    Image(systemName: "circle.fill")
//                                        .font(.caption)
//                                    Text("2 Motors")
//                                }
//                                .font(.subheadline)
//                                .fontWeight(.medium)
//                                .foregroundColor(coordinator.settings.motorCount == 2 ? .white : .primary)
//                                .frame(maxWidth: .infinity)
//                                .padding(.vertical, 12)
//                                .background(coordinator.settings.motorCount == 2 ? Color.blue : Color(.systemGray5))
//                                .cornerRadius(8, corners: [.topRight, .bottomRight])
//                            }
//                            .buttonStyle(PlainButtonStyle())
//                        }
//                    }
//                    .padding(.vertical, 8)
//                    
//                    // Visual indicator - FIXED
//                    HStack {
//                        Text("Current Setting:")
//                            .foregroundColor(.secondary)
//                            .font(.subheadline)
//                        Spacer()
//                        HStack(spacing: 6) {
//                            ForEach(0..<coordinator.settings.motorCount, id: \.self) { _ in
//                                Circle()
//                                    .fill(Color.green)
//                                    .frame(width: 10, height: 10)
//                            }
//                            Text("\(coordinator.settings.motorCount) motor\(coordinator.settings.motorCount > 1 ? "s" : "") active")
//                                .font(.subheadline)
//                                .foregroundColor(.green)
//                                .fontWeight(.medium)
//                        }
//                    }
//                    .padding(.vertical, 4)
//                    
//                    Picker("Lead Time Before Turn", selection: $coordinator.settings.leadTime) {
//                        ForEach(LeadTime.allCases, id: \.self) { leadTime in
//                            Text(leadTime.displayName).tag(leadTime)
//                        }
//                    }
//                }
//                
//                // Navigation Preferences
//                Section("Navigation Preferences") {
//                    Picker("Default Transport Mode", selection: $coordinator.settings.transportMode) {
//                        ForEach(TransportMode.allCases, id: \.self) { mode in
//                            HStack {
//                                Image(systemName: mode.systemImage)
//                                Text(mode.displayName)
//                            }
//                            .tag(mode)
//                        }
//                    }
//                }
//                
//                // About Section
//                Section("About") {
//                    HStack {
//                        Text("Version")
//                        Spacer()
//                        Text("1.0.0")
//                            .foregroundColor(.secondary)
//                    }
//                    
//                    HStack {
//                        Text("App Name")
//                        Spacer()
//                        Text("Glove Guide")
//                            .foregroundColor(.secondary)
//                    }
//                    
//                    HStack {
//                        Text("Configuration")
//                        Spacer()
//                        Text("Right Glove (Dual Motors)")
//                            .foregroundColor(.green)
//                            .font(.caption)
//                    }
//                }
//            }
//            .navigationTitle("Settings")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Done") {
//                        // Stop any active tests
//                        if testActive {
//                            bluetoothManager.testOff()
//                            testActive = false
//                        }
//                        presentationMode.wrappedValue.dismiss()
//                    }
//                }
//            }
//        }
//        .sheet(isPresented: $showingDeviceList) {
//            DeviceListView(bluetoothManager: bluetoothManager)
//        }
//        .onAppear {
//            // Sync motor count when settings open
//            if bluetoothManager.isConnected {
//                bluetoothManager.setMotorCount(coordinator.settings.motorCount)
//            }
//        }
//    }
//}
//
//// Helper extension for rounded corners on specific sides
//extension View {
//    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
//        clipShape(RoundedCorner(radius: radius, corners: corners))
//    }
//}
//
//struct RoundedCorner: Shape {
//    var radius: CGFloat = .infinity
//    var corners: UIRectCorner = .allCorners
//
//    func path(in rect: CGRect) -> Path {
//        let path = UIBezierPath(
//            roundedRect: rect,
//            byRoundingCorners: corners,
//            cornerRadii: CGSize(width: radius, height: radius)
//        )
//        return Path(path.cgPath)
//    }
//}
//
//struct DeviceListView: View {
//    @ObservedObject var bluetoothManager: BluetoothManager
//    @Environment(\.presentationMode) var presentationMode
//    @State private var isScanning = false
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                // Connection Status Banner
//                if bluetoothManager.isConnected {
//                    VStack(spacing: 8) {
//                        HStack(spacing: 16) {
//                            HStack(spacing: 6) {
//                                Image(systemName: "hand.point.right.fill")
//                                    .foregroundColor(.green)
//                                Text("Right Glove Connected")
//                                    .font(.caption)
//                                    .fontWeight(.semibold)
//                            }
//                            .padding(.horizontal, 12)
//                            .padding(.vertical, 6)
//                            .background(Color.green.opacity(0.1))
//                            .cornerRadius(8)
//                        }
//                    }
//                    .padding()
//                    .background(Color(.systemGray6))
//                }
//                
//                if bluetoothManager.discoveredDevices.isEmpty && !isScanning {
//                    emptyStateView
//                } else {
//                    deviceListContent
//                }
//            }
//            .navigationTitle("BLE Devices")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Cancel") {
//                        bluetoothManager.stopScanning()
//                        presentationMode.wrappedValue.dismiss()
//                    }
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(isScanning ? "Stop" : "Scan") {
//                        if isScanning {
//                            stopScanning()
//                        } else {
//                            startScanning()
//                        }
//                    }
//                }
//            }
//        }
//        .onAppear {
//            startScanning()
//        }
//        .onDisappear {
//            bluetoothManager.stopScanning()
//        }
//    }
//    
//    private var emptyStateView: some View {
//        VStack(spacing: 20) {
//            Image(systemName: "antenna.radiowaves.left.and.right")
//                .font(.system(size: 60))
//                .foregroundColor(.gray)
//            
//            Text("No devices found")
//                .font(.headline)
//                .foregroundColor(.gray)
//            
//            Text("Make sure your ESP32 is powered on and in range.")
//                .font(.body)
//                .foregroundColor(.secondary)
//                .multilineTextAlignment(.center)
//                .padding(.horizontal)
//            
//            Button("Start Scanning") {
//                startScanning()
//            }
//            .buttonStyle(.borderedProminent)
//        }
//    }
//    
//    private var deviceListContent: some View {
//        List {
//            if isScanning {
//                HStack {
//                    ProgressView()
//                        .scaleEffect(0.8)
//                    Text("Scanning for BLE devices...")
//                        .foregroundColor(.secondary)
//                }
//                .padding(.vertical, 8)
//            }
//            
//            Section(header: Text("\(bluetoothManager.discoveredDevices.count) device(s) found")) {
//                ForEach(bluetoothManager.discoveredDevices, id: \.identifier) { device in
//                    DeviceRow(
//                        device: device,
//                        isTarget: device.name?.contains("GloveGuide") ?? false
//                    ) {
//                        bluetoothManager.connect(to: device)
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                            presentationMode.wrappedValue.dismiss()
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    private func startScanning() {
//        isScanning = true
//        bluetoothManager.startScanning()
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
//            stopScanning()
//        }
//    }
//    
//    private func stopScanning() {
//        isScanning = false
//        bluetoothManager.stopScanning()
//    }
//}
//
//struct DeviceRow: View {
//    let device: CBPeripheral
//    let isTarget: Bool
//    let onConnect: () -> Void
//    
//    var body: some View {
//        Button(action: onConnect) {
//            HStack {
//                VStack(alignment: .leading, spacing: 4) {
//                    HStack {
//                        Text(device.name ?? "Unknown Device")
//                            .font(.headline)
//                            .foregroundColor(.primary)
//                        
//                        if isTarget {
//                            Text("🎯")
//                                .font(.title3)
//                        }
//                    }
//                    
//                    Text(device.identifier.uuidString)
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                        .lineLimit(1)
//                }
//                
//                Spacer()
//                
//                Image(systemName: "chevron.right")
//                    .foregroundColor(.gray)
//            }
//            .padding(.vertical, 4)
//        }
//        .buttonStyle(PlainButtonStyle())
//    }
//}
//
//#Preview {
//    SettingsView(coordinator: AppCoordinator())
//}
