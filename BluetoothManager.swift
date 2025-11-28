

//
//  BluetoothManager.swift
//  GloveGuide
//
//  Updated for DUAL GLOVE support (LEFT + RIGHT)
//

import Foundation
import CoreBluetooth
import Combine

class BluetoothManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    
    // LEFT Glove
    @Published var leftGloveConnected = false
    @Published var leftGloveStatus = "Disconnected"
    @Published var leftGloveDevice: CBPeripheral?
    
    // RIGHT Glove
    @Published var rightGloveConnected = false
    @Published var rightGloveStatus = "Disconnected"
    @Published var rightGloveDevice: CBPeripheral?
    
    // General
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var connectionStatus = "Disconnected"
    @Published var availableCharacteristics: [CBCharacteristic] = []
    
    // Convenience
    var isConnected: Bool {
        return leftGloveConnected || rightGloveConnected
    }
    
    var connectedDevice: CBPeripheral? {
        return leftGloveDevice ?? rightGloveDevice
    }
    
    // MARK: - Private Properties
    
    private var centralManager: CBCentralManager!
    
    // LEFT glove
    private var leftPeripheral: CBPeripheral?
    private var leftWriteCharacteristic: CBCharacteristic?
    
    // RIGHT glove
    private var rightPeripheral: CBPeripheral?
    private var rightWriteCharacteristic: CBCharacteristic?
    
    // Service UUIDs (same for both gloves)
    private let serviceUUID = CBUUID(string: "22345678-1234-1234-1234-123456789ABC")
    private let charUUID = CBUUID(string: "22345678-1234-1234-1234-123456789ABD")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            connectionStatus = "Bluetooth not available"
            print("❌ Bluetooth not powered on")
            return
        }
        
        discoveredDevices.removeAll()
        connectionStatus = "Scanning..."
        
        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])
        
        print("🔍 Started scanning for BLE devices...")
    }
    
    func stopScanning() {
        centralManager.stopScan()
        updateConnectionStatus()
        print("⏹️ Stopped scanning")
    }
    
    func connect(to peripheral: CBPeripheral) {
        print("🔄 Attempting to connect to: \(peripheral.name ?? "Unknown")")
        
        // Identify which glove this is
        if let name = peripheral.name {
            if name.contains("LEFT") {
                leftPeripheral = peripheral
                leftGloveStatus = "Connecting..."
                print("🫲 Connecting to LEFT glove")
            } else if name.contains("RIGHT") {
                rightPeripheral = peripheral
                rightGloveStatus = "Connecting..."
                print("🫱 Connecting to RIGHT glove")
            }
        }
        
        centralManager.connect(peripheral, options: [
            CBConnectPeripheralOptionNotifyOnConnectionKey: true,
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true
        ])
    }
    
    func disconnect(glove: GloveSide) {
        switch glove {
        case .left:
            guard let peripheral = leftPeripheral else { return }
            print("❌ Disconnecting LEFT glove")
            centralManager.cancelPeripheralConnection(peripheral)
            
        case .right:
            guard let peripheral = rightPeripheral else { return }
            print("❌ Disconnecting RIGHT glove")
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func disconnectAll() {
        if let left = leftPeripheral {
            centralManager.cancelPeripheralConnection(left)
        }
        if let right = rightPeripheral {
            centralManager.cancelPeripheralConnection(right)
        }
    }
    
    // MARK: - Motor Control Commands
    
    /// Set number of motors for a specific glove
    func setMotorCount(_ count: Int, for glove: GloveSide) {
        let command = count == 2 ? "M2" : "M1"
        sendCommand(command, to: glove)
        print("⚙️  Set \(glove) glove motor count to: \(count)")
    }
    
    /// Send LEFT turn command
    func sendLeftTurn() {
        sendCommand("L", to: .left)
        print("⬅️ Sent LEFT turn command")
    }
    
    /// Send RIGHT turn command
    func sendRightTurn() {
        sendCommand("R", to: .right)
        print("➡️ Sent RIGHT turn command")
    }
    
    /// Stop specific glove
    func stopGlove(_ glove: GloveSide) {
        sendCommand("0", to: glove)
        print("⏹️ Stopped \(glove) glove")
    }
    
    /// Stop all gloves
    func stopAll() {
        sendCommand("0", to: .left)
        sendCommand("0", to: .right)
        print("⏹️ Stopped ALL gloves")
    }
    
    /// Process haptic command from navigation
    func sendHapticCommand(_ command: HapticCommand) {
        switch command {
        case .left:
            sendCommand("L", to: .left)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.stopGlove(.left)
            }
            
        case .right:
            sendCommand("R", to: .right)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.stopGlove(.right)
            }
            
        case .straight:
            // Brief pulse on both gloves
            sendCommand("1", to: .left)
            sendCommand("1", to: .right)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.stopAll()
            }
            
        case .arrived, .stop:
            stopAll()
        }
    }
    
    // MARK: - Manual Test Controls
    
    func testOn(glove: GloveSide) {
        sendCommand("1", to: glove)
        print("🧪 TEST: \(glove) glove ON")
    }
    
    func testOff(glove: GloveSide) {
        sendCommand("0", to: glove)
        print("🧪 TEST: \(glove) glove OFF")
    }
    
    // MARK: - Private Methods
    
    private func sendCommand(_ command: String, to glove: GloveSide) {
        let peripheral: CBPeripheral?
        let characteristic: CBCharacteristic?
        
        switch glove {
        case .left:
            peripheral = leftPeripheral
            characteristic = leftWriteCharacteristic
        case .right:
            peripheral = rightPeripheral
            characteristic = rightWriteCharacteristic
        }
        
        guard let peripheral = peripheral,
              let characteristic = characteristic else {
            print("⚠️ Cannot send to \(glove) glove: Not connected")
            return
        }
        
        guard let data = command.data(using: .utf8) else {
            print("❌ Failed to convert command to data")
            return
        }
        
        let writeType: CBCharacteristicWriteType
        if characteristic.properties.contains(.write) {
            writeType = .withResponse
        } else if characteristic.properties.contains(.writeWithoutResponse) {
            writeType = .withoutResponse
        } else {
            print("❌ Characteristic does not support write")
            return
        }
        
        peripheral.writeValue(data, for: characteristic, type: writeType)
        print("✅ Sent '\(command)' to \(glove) glove")
    }
    
    private func autoSelectWriteCharacteristic(from characteristics: [CBCharacteristic], for peripheral: CBPeripheral) {
        for characteristic in characteristics {
            if characteristic.properties.contains(.write) ||
               characteristic.properties.contains(.writeWithoutResponse) {
                
                // Determine which glove this is
                if peripheral.identifier == leftPeripheral?.identifier {
                    leftWriteCharacteristic = characteristic
                    print("🔧 LEFT glove: Selected write characteristic")
                } else if peripheral.identifier == rightPeripheral?.identifier {
                    rightWriteCharacteristic = characteristic
                    print("🔧 RIGHT glove: Selected write characteristic")
                }
                return
            }
        }
        print("⚠️ No writable characteristic found")
    }
    
    private func updateConnectionStatus() {
        if leftGloveConnected && rightGloveConnected {
            connectionStatus = "Both gloves connected"
        } else if leftGloveConnected {
            connectionStatus = "Left glove connected"
        } else if rightGloveConnected {
            connectionStatus = "Right glove connected"
        } else {
            connectionStatus = "Disconnected"
        }
    }
}

// MARK: - GloveSide Enum
enum GloveSide: String {
    case left = "LEFT"
    case right = "RIGHT"
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("📱 Bluetooth state changed: \(central.state.rawValue)")
        
        switch central.state {
        case .poweredOn:
            connectionStatus = "Ready to scan"
            print("✅ Bluetooth powered ON")
        case .poweredOff:
            connectionStatus = "Bluetooth is off"
            print("❌ Bluetooth powered OFF")
        case .unauthorized:
            connectionStatus = "Bluetooth access denied"
            print("🚫 Bluetooth unauthorized")
        case .unsupported:
            connectionStatus = "Bluetooth not supported"
            print("❌ Bluetooth unsupported")
        default:
            connectionStatus = "Bluetooth unavailable"
            print("⚠️ Bluetooth state: \(central.state.rawValue)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let deviceName = peripheral.name ?? "Unknown"
        
        if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            DispatchQueue.main.async {
                self.discoveredDevices.append(peripheral)
                
                if deviceName.contains("GloveGuide") {
                    print("📡 Discovered: \(deviceName) 🎯")
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ Connected to: \(peripheral.name ?? "Unknown")")
        
        // Identify which glove
        if peripheral.identifier == leftPeripheral?.identifier {
            DispatchQueue.main.async {
                self.leftGloveConnected = true
                self.leftGloveStatus = "Connected"
                self.leftGloveDevice = peripheral
                print("🫲 LEFT glove connected")
            }
        } else if peripheral.identifier == rightPeripheral?.identifier {
            DispatchQueue.main.async {
                self.rightGloveConnected = true
                self.rightGloveStatus = "Connected"
                self.rightGloveDevice = peripheral
                print("🫱 RIGHT glove connected")
            }
        }
        
        DispatchQueue.main.async {
            self.updateConnectionStatus()
        }
        
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        print("🔍 Discovering services...")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("❌ Connection failed: \(error?.localizedDescription ?? "Unknown error")")
        
        if peripheral.identifier == leftPeripheral?.identifier {
            DispatchQueue.main.async {
                self.leftGloveConnected = false
                self.leftGloveStatus = "Connection failed"
                self.leftPeripheral = nil
            }
        } else if peripheral.identifier == rightPeripheral?.identifier {
            DispatchQueue.main.async {
                self.rightGloveConnected = false
                self.rightGloveStatus = "Connection failed"
                self.rightPeripheral = nil
            }
        }
        
        DispatchQueue.main.async {
            self.updateConnectionStatus()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("🔌 Disconnected: \(peripheral.name ?? "Unknown")")
        
        if peripheral.identifier == leftPeripheral?.identifier {
            DispatchQueue.main.async {
                self.leftGloveConnected = false
                self.leftGloveStatus = "Disconnected"
                self.leftGloveDevice = nil
                self.leftPeripheral = nil
                self.leftWriteCharacteristic = nil
                print("🫲 LEFT glove disconnected")
            }
        } else if peripheral.identifier == rightPeripheral?.identifier {
            DispatchQueue.main.async {
                self.rightGloveConnected = false
                self.rightGloveStatus = "Disconnected"
                self.rightGloveDevice = nil
                self.rightPeripheral = nil
                self.rightWriteCharacteristic = nil
                print("🫱 RIGHT glove disconnected")
            }
        }
        
        DispatchQueue.main.async {
            self.updateConnectionStatus()
        }
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("❌ Service discovery error: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else {
            print("⚠️ No services found")
            return
        }
        
        let gloveName = peripheral.name ?? "Unknown"
        print("📋 [\(gloveName)] Found \(services.count) service(s)")
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("❌ Characteristic discovery error: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            print("⚠️ No characteristics found")
            return
        }
        
        let gloveName = peripheral.name ?? "Unknown"
        print("📝 [\(gloveName)] Found \(characteristics.count) characteristic(s)")
        
        var writableFound = false
        for characteristic in characteristics {
            let properties = characteristic.properties
            
            if !writableFound && (properties.contains(.write) || properties.contains(.writeWithoutResponse)) {
                writableFound = true
                DispatchQueue.main.async {
                    self.autoSelectWriteCharacteristic(from: characteristics, for: peripheral)
                }
            }
        }
        
        if writableFound {
            print("✅ [\(gloveName)] Ready for commands")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("❌ Write error: \(error.localizedDescription)")
        }
    }
}



