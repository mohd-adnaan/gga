# Glove Guide - Haptic Navigation System

A SwiftUI app that provides turn-by-turn navigation using Apple Maps and transmits directional cues via Bluetooth to external haptic devices (gloves with ESP32 controllers).

## Features

### ✅ Implemented Core Features
- **Home Screen**: Apple Maps integration with search functionality and transport mode selection
- **Active Navigation**: Full-screen map with route display and navigation info panel
- **End Navigation**: Confirmation dialog for ending navigation
- **Bluetooth Integration**: Core Bluetooth framework for ESP32 communication
- **Settings**: Vibration intensity, lead time, progressive intensity controls
- **MVVM Architecture**: Clean separation of concerns with proper data flow

### 🎯 Key Components

1. **Navigation Manager**: Handles MapKit integration, route calculation, and turn detection
2. **Bluetooth Manager**: Manages BLE connections to ESP32 haptic devices
3. **App Settings**: Persistent settings with UserDefaults
4. **Search System**: Location search with autocomplete using MKLocalSearchCompleter

## Setup Instructions

### 1. Xcode Configuration

Add these permissions to your `Info.plist`:

```xml
<!-- Location Services -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>GloveGuide needs location access to provide turn-by-turn haptic navigation.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>GloveGuide needs location access to continue navigation in the background.</string>

<!-- Bluetooth -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>GloveGuide uses Bluetooth to communicate with your haptic glove device.</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>GloveGuide connects to your haptic glove device via Bluetooth for navigation feedback.</string>

<!-- Background Modes (Optional) -->
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>bluetooth-central</string>
</array>
```

### 2. Target Requirements
- iOS 16.0+
- Core Location
- MapKit
- Core Bluetooth

### 3. ESP32 Device Setup

Your ESP32 device should advertise with:
- **Service UUID**: `12345678-1234-1234-1234-123456789ABC`
- **Direction Characteristic**: `12345678-1234-1234-1234-123456789ABD` (Write)
- **Status Characteristic**: `12345678-1234-1234-1234-123456789ABE` (Read)
- **Settings Characteristic**: `12345678-1234-1234-1234-123456789ABF` (Write)

## Usage

### Basic Navigation Flow

1. **Search for Destination**: Tap the search bar and enter your destination
2. **Select Transport Mode**: Choose between "Pedestrian" and "Biker"
3. **Connect Bluetooth Device**: Go to Settings > Bluetooth Connection > Connect
4. **Start Navigation**: Select a destination to begin route calculation
5. **Receive Haptic Feedback**: The app sends turn commands to your glove device:
   - `"LEFT"` - Left turn ahead
   - `"RIGHT"` - Right turn ahead
   - `"STRAIGHT"` - Continue straight
   - `"ARRIVED"` - Destination reached
   - `"STOP"` - Navigation stopped

### Settings Configuration

- **Vibration Intensity**: 0-100% (sent to ESP32)
- **Lead Time**: 0, 10, or 20 seconds before turns
- **Progressive Intensity**: Increasing vibration as turn approaches
- **Transport Mode**: Default preference for navigation type

## Testing

### Simulator Testing
The app works in the iOS Simulator with simulated location:
1. In Simulator: Device > Location > Custom Location
2. Enter coordinates for testing
3. Use "Freeway Drive" for route testing

### Bluetooth Testing
Without physical ESP32 device:
1. The app will show "Disconnected" status
2. Haptic commands are logged to Xcode console
3. All other functionality works normally

### Physical Device Testing
With actual iPhone and ESP32 glove:
1. Enable Bluetooth on iPhone
2. Put ESP32 in advertising mode
3. Open Settings in app and scan for devices
4. Connect to your ESP32 device
5. Test with real navigation

## Architecture

### MVVM Pattern
- **Models**: `HapticCommand`, `AppSettings`, `TransportMode`, `NavigationState`
- **ViewModels**: `NavigationManager`, `BluetoothManager`, `AppCoordinator`
- **Views**: `HomeView`, `NavigationView`, `SettingsView`, `SearchView`, `EndNavigationView`

### Data Flow
1. User searches for destination in `HomeView`
2. `AppCoordinator` receives destination and calls `NavigationManager`
3. `NavigationManager` calculates route using MapKit
4. During navigation, location updates trigger turn detection
5. Turn commands sent via `BluetoothManager` to ESP32
6. Settings synchronized between app and device

## Safety Considerations

- Large, easy-to-tap buttons for cyclists with gloves
- High contrast for outdoor visibility
- Quick access to stop navigation
- Bluetooth connection status always visible
- Error handling for connectivity issues

## Future Enhancements

- [ ] Voice feedback as backup
- [ ] Night mode with dark map style
- [ ] Route preferences (bike-friendly, shortest vs safest)
- [ ] Offline navigation support
- [ ] Background navigation
- [ ] Multiple haptic devices support
- [ ] Custom vibration patterns

## Troubleshooting

### Common Issues

1. **Location Permission Denied**
   - Go to iPhone Settings > Privacy & Security > Location Services
   - Enable for GloveGuide

2. **Bluetooth Connection Fails**
   - Ensure ESP32 is advertising with correct service UUID
   - Check iOS Bluetooth is enabled
   - Try resetting ESP32 device

3. **Route Calculation Fails**
   - Check internet connection
   - Verify destination address is valid
   - Try different search terms

4. **Haptic Commands Not Working**
   - Verify Bluetooth connection status
   - Check ESP32 characteristic UUIDs match
   - Monitor Xcode console for BLE errors

## Development Notes

- Use Xcode's Location Simulator for testing routes
- Monitor Core Bluetooth logs for debugging connections
- Test with various transport modes and settings
- Validate turn detection with different route types
- Ensure proper memory management with location services

## License

This project is designed for educational and personal use. Please ensure compliance with Apple's App Store guidelines if publishing.