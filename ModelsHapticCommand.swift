//
//  HapticCommand.swift
//  GloveGuide
//
//  Created by Mohammad Adnaan on 2025-10-26.
//

import Foundation

enum HapticCommand: String, CaseIterable {
    case left = "LEFT"
    case right = "RIGHT"
    case stop = "STOP"
    case arrived = "ARRIVED"
    case straight = "STRAIGHT"
}

enum TransportMode: String, CaseIterable {
    case walking = "WALKING"
    case cycling = "CYCLING"
    
    var displayName: String {
        switch self {
        case .walking:
            return "Pedestrian"
        case .cycling:
            return "Biker"
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

enum NavigationState {
    case idle
    case searchingRoute
    case navigating
    case arrived
}