//
//  BluetoothManager.swift
//  GloveGuide
//
//  Created by Mohammad Adnaan on 2025-10-26.
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
    
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var directionCharacteristic: CBCharacteristic?
    private var statusCharacteristic: CBCharacteristic?
    private var settingsCharacteristic: CBCharacteristic?
    
    // Custom UUIDs for GloveGuide service
    private let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABC")
    private let directionCharacteristicUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABD")
    private let statusCharacteristicUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABE")
    private let settingsCharacteristicUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABF")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            connectionStatus = "Bluetooth not available"
            return
        }
        
        discoveredDevices.removeAll()
        connectionStatus = "Scanning..."
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
    }
    
    func stopScanning() {
        centralManager.stopScan()
        connectionStatus = isConnected ? "Connected" : "Disconnected"
    }
    
    func connect(to peripheral: CBPeripheral) {
        stopScanning()
        connectedPeripheral = peripheral
        connectionStatus = "Connecting..."
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    func sendHapticCommand(_ command: HapticCommand) {
        guard let peripheral = connectedPeripheral,
              let characteristic = directionCharacteristic else {
            print("Cannot send command: Not connected or characteristic not found")
            return
        }
        
        let data = command.rawValue.data(using: .utf8)!
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        print("Sent haptic command: \(command.rawValue)")
    }
    
    func syncSettings(intensity: Double, leadTime: LeadTime, progressiveEnabled: Bool) {
        guard let peripheral = connectedPeripheral,
              let characteristic = settingsCharacteristic else {
            return
        }
        
        let settingsDict: [String: Any] = [
            "intensity": intensity,
            "leadTime": leadTime.rawValue,
            "progressive": progressiveEnabled
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: settingsDict),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let data = jsonString.data(using: .utf8)!
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            connectionStatus = "Ready to scan"
        case .poweredOff:
            connectionStatus = "Bluetooth is off"
        case .unauthorized:
            connectionStatus = "Bluetooth access denied"
        case .unsupported:
            connectionStatus = "Bluetooth not supported"
        default:
            connectionStatus = "Bluetooth unavailable"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredDevices.contains(peripheral) {
            discoveredDevices.append(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionStatus = "Connected"
        isConnected = true
        connectedDevice = peripheral
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectionStatus = "Connection failed"
        isConnected = false
        connectedPeripheral = nil
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectionStatus = "Disconnected"
        isConnected = false
        connectedDevice = nil
        connectedPeripheral = nil
        directionCharacteristic = nil
        statusCharacteristic = nil
        settingsCharacteristic = nil
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            if service.uuid == serviceUUID {
                peripheral.discoverCharacteristics([
                    directionCharacteristicUUID,
                    statusCharacteristicUUID,
                    settingsCharacteristicUUID
                ], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            switch characteristic.uuid {
            case directionCharacteristicUUID:
                directionCharacteristic = characteristic
            case statusCharacteristicUUID:
                statusCharacteristic = characteristic
                peripheral.readValue(for: characteristic)
            case settingsCharacteristicUUID:
                settingsCharacteristic = characteristic
            default:
                break
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Write error: \(error.localizedDescription)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // Handle status updates from the device if needed
    }
}