//
//  AppSettings.swift
//  GloveGuide
//
//  Created by Mohammad Adnaan on 2025-10-26.
//

import Foundation
import Combine

class AppSettings: ObservableObject {
    @Published var vibrationIntensity: Double {
        didSet {
            UserDefaults.standard.set(vibrationIntensity, forKey: "vibrationIntensity")
        }
    }
    
    @Published var leadTime: LeadTime {
        didSet {
            UserDefaults.standard.set(leadTime.rawValue, forKey: "leadTime")
        }
    }
    
    @Published var progressiveIntensityEnabled: Bool {
        didSet {
            UserDefaults.standard.set(progressiveIntensityEnabled, forKey: "progressiveIntensityEnabled")
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
        self.vibrationIntensity = UserDefaults.standard.object(forKey: "vibrationIntensity") as? Double ?? 50.0
        self.leadTime = LeadTime(rawValue: UserDefaults.standard.integer(forKey: "leadTime")) ?? .tenSeconds
        self.progressiveIntensityEnabled = UserDefaults.standard.object(forKey: "progressiveIntensityEnabled") as? Bool ?? true
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
            return 10 // meters, assuming ~1m/s walking speed
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
