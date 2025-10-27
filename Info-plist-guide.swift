//
//  Info.plist Configuration Guide
//  GloveGuide
//
//  You'll need to add these keys to your Info.plist file:
//

/*
Required permissions for your Info.plist:

1. Location Services:
<key>NSLocationWhenInUseUsageDescription</key>
<string>GloveGuide needs location access to provide turn-by-turn haptic navigation.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>GloveGuide needs location access to continue navigation in the background.</string>

2. Bluetooth:
<key>NSBluetoothAlwaysUsageDescription</key>
<string>GloveGuide uses Bluetooth to communicate with your haptic glove device.</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>GloveGuide connects to your haptic glove device via Bluetooth for navigation feedback.</string>

3. Background App Refresh (optional, for continued navigation):
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>bluetooth-central</string>
</array>

4. Required device capabilities:
<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>location-services</string>
    <string>bluetooth-le</string>
</array>

5. Supported interface orientations (lock to portrait for safety):
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
</array>

6. App Transport Security (if needed for any web requests):
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>
*/