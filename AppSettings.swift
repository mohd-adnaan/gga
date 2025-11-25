//
//  AppSettings.swift
//  GloveGuide
//
//  SIMPLIFIED - No Progressive Intensity
//

import Foundation
import Combine

class AppSettings: ObservableObject {
    @Published var motorCount: Int {
        didSet {
            UserDefaults.standard.set(motorCount, forKey: "motorCount")
        }
    }
    
    @Published var leadTime: LeadTime {
        didSet {
            UserDefaults.standard.set(leadTime.rawValue, forKey: "leadTime")
        }
    }
    
    @Published var transportMode: TransportMode {
        didSet {
            UserDefaults.standard.set(transportMode.rawValue, forKey: "transportMode")
        }
    }
    
    @Published var lastConnectedDeviceUUID: String? {
        didSet {
            UserDefaults.standard.set(lastConnectedDeviceUUID, forKey: "lastConnectedDeviceUUID")
        }
    }
    
    init() {
        self.motorCount = UserDefaults.standard.object(forKey: "motorCount") as? Int ?? 1
        self.leadTime = LeadTime(rawValue: UserDefaults.standard.integer(forKey: "leadTime")) ?? .tenSeconds
        self.transportMode = TransportMode(rawValue: UserDefaults.standard.string(forKey: "transportMode") ?? "") ?? .walking
        self.lastConnectedDeviceUUID = UserDefaults.standard.string(forKey: "lastConnectedDeviceUUID")
    }
}

enum LeadTime: Int, CaseIterable {
    case immediate = 0
    case tenSeconds = 10
    case twentySeconds = 20
    
    var displayName: String {
        switch self {
        case .immediate:
            return "0 sec"
        case .tenSeconds:
            return "10 sec"
        case .twentySeconds:
            return "20 sec"
        }
    }
    
    var distance: Double {
        switch self {
        case .immediate:
            return 0
        case .tenSeconds:
            return 10
        case .twentySeconds:
            return 20
        }
    }
}

enum TransportMode: String, CaseIterable {
    case walking = "walking"
    case cycling = "cycling"
    
    var displayName: String {
        switch self {
        case .walking:
            return "Walking"
        case .cycling:
            return "Cycling"
        }
    }
    
    var systemImage: String {
        switch self {
        case .walking:
            return "figure.walk"
        case .cycling:
            return "bicycle"
        }
    }
}
