# Creating a VPN app with WireGuardKit


This document explains the steps involved in creating a VPN application (iOS /
macOS) from scratch with WireGuardKit.

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

## Create a basic custom-VPN Xcode project

### Create an Xcode project

 1. In Xcode, go to _File > New > Project_, select _App_ (under either
    the _iOS_ or _macOS_ tab, depending on which platform you want),
    click _Next_.
 2. Set _Product Name_ to an app name of your choice.
 3. Ensure _Team_ and _Organization Identifier_ are set correctly.
    Ensure that the _Bundle Identifier_ is a unique name that has not
    been previously used for some other project. Select other options as
    applicable. Click _Next_.
 4. Select a directory to create the project. Click _Create_.

### Set Capabilities for the App

 5. In Xcode, go to the _Signing & Capabilities_ tab for the app target
 6. Click on _+ Capability_, add _Network Extensions_, ensure _Packet
    Tunnel_ is checked. This would add the required entitlements.
 7. Ensure _Automatically manage signing_ is checked. Ensure that _Team_
    is set correctly. Ensure that _Provisioning Profile_ and _Signing
    Certificate_ fields are shown without errors.

### Add Tunnel Extension

 8. In Xcode, go to _File > New > Target_, select _Network Extension_ (under
    either the _iOS_ or _macOS_ tab, depending on which platform you want).
    Click _Next_.
 9. Set _Product Name_ to an extension name of your choice, say
    "TunnelExtension".
10. Ensure _Provider Type_ is set to _Packet Tunnel_.
11. Ensure _Team_ is set correctly. Click _Finish_. Xcode will automatically
    create provisioning profiles for this target. In case Xcode prompts you to
    activate the "TunnelExtension" scheme, select _Cancel_.

### Set Capabilities for the Tunnel Extension

12. In Xcode, go to the _Signing & Capabilities_ tab for the tunnel extension
    target
13. Click on _+ Capability_, add _Network Extensions_, ensure _Packet Tunnel_
    is checked. This would add the required entitlements.
14. Ensure _Automatically manage signing_ is checked. Ensure that _Team_ is set
    correctly. Ensure that _Provisioning Profile_ and _Signing Certificate_
    fields are shown without errors.

### Parametrize using xcconfig

This enables the codebase to be used by multiple developers with different
Apple Developer accounts.

15. Create an xcconfig file, say "Development.xcconfig" with the
    `APP_ID` and `DEVELOPMENT_TEAM` fields set to
    appropriate values.
    ~~~
    APP_ID = <your-app-bundle-id>
    DEVELOPMENT_TEAM = <your-apple-developer-id>
    ~~~
    Ideally, this file should be kept private and out of version control.
16. In Xcode's project navigator, select the project at the top. Right click on
    the selected item, then click on the _Add files to_ menu item. Select the
created xcconfig, click _Add_.
17. In Xcode's project navigator, select the project at the top. To that right
    of the project navigator, select the project in the _Project_ section.
18. Under _Configurations_, it should show "No Configurations Set" for both
    _Debug_ and _Release_. Expand both _Debug_ and _Release_. For both _Debug_
    and _Release_, for the main app, set the configuration files to the
    "Development.xcconfig" file you created earlier.
19. Open the project.pbxproj file in a text editor.

    Change all values of `DEVELOPMENT_TEAM` to inherited, like:
    ~~~
    DEVELOPMENT_TEAM = "$(inherited)";
    ~~~

    Change all instances of the bundle id to `${APP_ID}`, like:

    ~~~
    PRODUCT_BUNDLE_IDENTIFIER = "${APP_ID}";
    ~~~

    and, assuming your tunnel extension name is "TunnelExtension":

    ~~~
    PRODUCT_BUNDLE_IDENTIFIER = "${APP_ID}.TunnelExtension";
    ~~~

## Test tunneling

### Setup a tunnel configuration

20. Open the App Delegate file (if you're using SwiftUI, you will need to
    create an App Delegate file and set it using the
    `UIApplicationDelegateAdaptor` property wrapper).
21. Add code in the App Delegate to save the tunnel configuration and
    start the tunnel. 
    (Commit: 
    [iOS](https://github.com/roop/using-wireguardkit/commit/04064ea))

### Make the tunnel extension succeed

22. Open PacketTunnelProvider.swift in the tunnel extension. Make the
    `startTunnel` function call the supplied completion handler, so that the OS
    considers the tunnel to be established.
    (Commit:
    [iOS](https://github.com/roop/using-wireguardkit/commit/f12bb15))

### Run the app

23. Build and run the app on a test device (don't use the iOS Simulator).

    The first time you run it, the OS will ask for permissions to add a VPN
    configuration, which you should approve.

    Open Console.app and search for the text from the logs printed from the
    tunnel extension to make sure the tunnel is running.

    The VPN badge is not shown at this stage in iOS. It's probably because we
    haven't setup the network settings, but I'm not sure.

## Integrate WireGuardKit

### Add the WireGuardKit package

24. In Xcode, go to _File > Add Packages_.
25. In the search field, paste the URL for the official wireguard-apple
    repository: `https://git.zx2c4.com/wireguard-apple`.
26. Select 'wireguard-apple', choose the dependency rule you want, click _Add
    Package_.

### Setup a build script for WireGuardGoBridge

This differs from how it's recommended in the wireguard-apple README
because the `${BUILD_DIR%Build/*}` used there doesn't seem to work in Xcode 13
(and maybe in Xcode 12 too).

27. Write a script to build WireGuardGoBridge.
    ([Commit](https://github.com/roop/using-wireguardkit/commit/66f5dee))
28. In Xcode, go to _File > New > Target_, select _External Build System_ under
    the _Other_ tab, click _Next_. Set _Product Name_ as "WireGuardGoBridge".
    We're using a Perl script, so we set _Build Tool_ as "/usr/bin/perl".
    Click _Finish_.
29. Go to the _Info_ tab for the "WireGuardGoBridge" target. Change _Arguments_
    to the path to the Perl script. You can use "$PROJECT_DIR" in the path,
    where $PROJECT_DIR is the directory that contains the Xcode project
    (i.e. contains the the Something.xcodeproj package).

### Setup building of WireGuardGoBridge

30. Go to the _Build Settings_ tab for the "WireGuardGoBridge" target. Set
    _SDKROOT_ to `iphoneos` (if you're building for iOS), or `macosx` (if
    you're building for macOS). Xcode's default value seems to be `iphoneos`.
31. Select the tunnel extension target, go to the _Build Phases_ tab. Expand
    the _Dependencies_ section, click on the "+" to add a dependency to the
    "WireGuardGoBridge" target.
32. Select the tunnel extension target, go to the _Build Phases_ tab. Expand
    the _Link Binary With Libraries_ section, click on "+" to add
    "WireGuardKit"

### Disable bitcode

33. If you're building for iOS, go to the project's _Build Settings_, search
    for "bitcode", and set _Enable Bitcode_ to "No".

### Use WireGuardKit in the tunnel extension code

34. Copy `Sources/Shared/Model/TunnelConfiguration+WgQuickConfig.swift` and
    `Sources/Shared/Model/String+ArrayConversion.swift` from
    the wireguard-apple repository and add them to the tunnel extension.
35. Import WireGuardKit in "TunnelConfiguration+WgQuickConfig.swift"
    (Commit:
    [iOS](https://github.com/roop/using-wireguardkit/commit/5054b32))
36. Modify PacketTunnelProvider.swift in the tunnel extension to use
    WireGuardAdapter from WireGuardKit. (Commit: [iOS](https://github.com/roop/using-wireguardkit/commit/bbe787b))
37. Modify AppDelegate to pass the WireGuard config to the tunnel extension.
    (Commit:
    [iOS](https://github.com/roop/using-wireguardkit/commit/252532e))

<small>Copyright 2021-22 Roopesh Chander. Licensed under <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-sa/4.0/80x15.png" /></a>.</small>
