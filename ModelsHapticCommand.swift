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



enum NavigationState {
    case idle
    case searchingRoute
    case navigating
    case arrived
}