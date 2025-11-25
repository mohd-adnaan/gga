//
//  BluetoothManager.swift
//  GloveGuide
//
//  RIGHT GLOVE ONLY - WITH DUAL MOTOR SUPPORT
//

import Foundation
import CoreBluetooth
import Combine

class BluetoothManager: NSObject, ObservableObject {
    // MARK: - Properties
    @Published var isConnected = false
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var connectionStatus = "Disconnected"
    @Published var connectedDevice: CBPeripheral?
    @Published var availableCharacteristics: [CBCharacteristic] = []
    
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    
    // RIGHT Glove Service UUIDs
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
        
        print("🔍 Started scanning for ALL BLE devices...")
    }
    
    func stopScanning() {
        centralManager.stopScan()
        connectionStatus = isConnected ? "Connected" : "Disconnected"
        print("⏹️ Stopped scanning")
    }
    
    func connect(to peripheral: CBPeripheral) {
        stopScanning()
        connectedPeripheral = peripheral
        connectionStatus = "Connecting..."
        print("🔄 Attempting to connect to: \(peripheral.name ?? "Unknown")")
        
        centralManager.connect(peripheral, options: [
            CBConnectPeripheralOptionNotifyOnConnectionKey: true,
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true
        ])
    }
    
    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        print("❌ Disconnecting from: \(peripheral.name ?? "Unknown")")
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    // MARK: - Motor Control Commands
    
    /// Set number of motors to use (1 or 2)
    func setMotorCount(_ count: Int) {
        let command = count == 2 ? "M2" : "M1"
        sendCommand(command)
        print("⚙️  Set motor count to: \(count)")
    }
    
    /// Send RIGHT turn command
    func sendRightTurn() {
        sendCommand("R")
        print("➡️ Sent RIGHT turn command")
    }
    
    /// Send generic ON command
    func sendTurnOn() {
        sendCommand("1")
        print("✅ Sent turn ON command")
    }
    
    /// Send generic OFF command
    func sendTurnOff() {
        sendCommand("0")
        print("⏹️ Sent turn OFF command")
    }
    
    /// Stop vibration
    func stopAll() {
        sendCommand("0")
        print("⏹️ Stopped vibration")
    }
    
    /// Process haptic command from navigation
    func sendHapticCommand(_ command: HapticCommand) {
        switch command {
        case .right:
            sendRightTurn()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.stopAll()
            }
            
        case .left:
            sendRightTurn()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.stopAll()
            }
            
        case .straight:
            sendTurnOn()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.stopAll()
            }
            
        case .arrived, .stop:
            stopAll()
        }
    }
    
    // MARK: - Manual Test Controls
    
    func testOn() {
        sendCommand("1")
        print("🧪 TEST: Glove ON")
    }
    
    func testOff() {
        sendCommand("0")
        print("🧪 TEST: Glove OFF")
    }
    
    // MARK: - Private Methods
    
    private func sendCommand(_ command: String) {
        guard let peripheral = connectedPeripheral,
              let characteristic = writeCharacteristic else {
            print("⚠️ Cannot send command: Not connected")
            return
        }
        
        guard let data = command.data(using: .utf8) else {
            print("❌ Failed to convert command to data")
            return
        }
        
        let writeType: CBCharacteristicWriteType
        if characteristic.properties.contains(.write) {
            writeType = .withResponse
            print("✅ Sent command: '\(command)' (with response)")
        } else if characteristic.properties.contains(.writeWithoutResponse) {
            writeType = .withoutResponse
            print("✅ Sent command: '\(command)' (without response)")
        } else {
            print("❌ Characteristic does not support write")
            return
        }
        
        peripheral.writeValue(data, for: characteristic, type: writeType)
    }
    
    private func autoSelectWriteCharacteristic(from characteristics: [CBCharacteristic]) {
        for characteristic in characteristics {
            if characteristic.properties.contains(.write) ||
               characteristic.properties.contains(.writeWithoutResponse) {
                writeCharacteristic = characteristic
                print("🔧 Auto-selected write characteristic: \(characteristic.uuid)")
                return
            }
        }
        print("⚠️ No writable characteristic found")
    }
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
        print("📡 Discovered: \(deviceName) | RSSI: \(RSSI) dB")
        
        if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            DispatchQueue.main.async {
                self.discoveredDevices.append(peripheral)
                print("➕ Added to list: \(deviceName)")
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ Connected to: \(peripheral.name ?? "Unknown")")
        
        DispatchQueue.main.async {
            self.connectionStatus = "Connected"
            self.isConnected = true
            self.connectedDevice = peripheral
        }
        
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        print("🔍 Discovering services...")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("❌ Connection failed: \(error?.localizedDescription ?? "Unknown error")")
        
        DispatchQueue.main.async {
            self.connectionStatus = "Connection failed"
            self.isConnected = false
            self.connectedPeripheral = nil
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("🔌 Disconnected: \(peripheral.name ?? "Unknown")")
        
        DispatchQueue.main.async {
            self.connectionStatus = "Disconnected"
            self.isConnected = false
            self.connectedDevice = nil
            self.connectedPeripheral = nil
            self.writeCharacteristic = nil
            self.availableCharacteristics = []
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
        
        print("📋 Found \(services.count) service(s):")
        for service in services {
            print("   • Service: \(service.uuid)")
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
        
        print("📝 Found \(characteristics.count) characteristic(s):")
        
        var writableFound = false
        for characteristic in characteristics {
            let properties = characteristic.properties
            var propertyString = ""
            
            if properties.contains(.read) { propertyString += "READ " }
            if properties.contains(.write) { propertyString += "WRITE " }
            if properties.contains(.writeWithoutResponse) { propertyString += "WRITE_NO_RESP " }
            if properties.contains(.notify) { propertyString += "NOTIFY " }
            
            print("   • \(characteristic.uuid) | \(propertyString)")
            
            DispatchQueue.main.async {
                self.availableCharacteristics.append(characteristic)
            }
            
            if !writableFound && (properties.contains(.write) || properties.contains(.writeWithoutResponse)) {
                writableFound = true
                DispatchQueue.main.async {
                    self.autoSelectWriteCharacteristic(from: characteristics)
                }
            }
        }
        
        if writableFound {
            print("✅ RIGHT glove ready for commands")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("❌ Write error: \(error.localizedDescription)")
        } else {
            print("✅ Write successful")
        }
    }
}

extension Data {
    var hexString: String {
        return map { String(format: "%02x", $0) }.joined(separator: " ")
    }
}
