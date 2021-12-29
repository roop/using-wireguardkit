# Trying out this app

## Requirements

- Xcode 13
- Doesn't work on the iOS Simulator

## Caveats

To keep it simple, the following are omitted:

  - Keychain:

    This app passes the wg-quick config to the tunnel extension in plaintext.
    It's more secure to pass it through the keychain, like the official WireGuard
    app.

  - App Groups:

    To have a shared location for writing the tunnel log, we will need an app
    group, which is not setup here.

## Running the iOS app

To try out running the iOS app, do the following:

 1. Copy iOS/Developer.xcconfig.template to iOS/Developer.xcconfig and fill in:
      - `APP_ID`: The explicit bundle id of the VPN application
      - `DEVELOPMENT_TEAM`: The Apple Developer account id

 2. Open "iOS/UsingWireGuardKit/UsingWireGuardKit.xcodeproj" in Xcode

 3. Open "AppDelegate.swift" for editing

 4. Change the line that sets `protocolConfiguration.providerBundleIdentifier`
    to set the bundle id of the tunnel extension. For example, if you app's
    bundle id is `net.example.UsingWireGuardKit`, set it as:

    ~~~
    protocolConfiguration.providerBundleIdentifier = "net.example.UsingWireGuardKit.TunnelExtension"
    ~~~

 5. Set the value of `wgQuickConfig` to the wg-quick config:

    ~~~
    let wgQuickConfig = <wg-quick config string>
    ~~~

 6. Build and run. The app turns the tunnel on for 20 seconds and then turn it
    off. You can try opening something in iOS Safari while the tunnel is on.
