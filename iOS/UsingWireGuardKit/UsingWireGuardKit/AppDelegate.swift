//
//  AppDelegate.swift
//  UsingWireGuardKit
//
//  Created by Roopesh Chander S on 27/12/21.
//

import UIKit
import NetworkExtension

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        turnOnTunnel { isSuccess in
            if isSuccess {
                NSLog("Starting tunnel succeeded")
                NSLog("Will turn off in 20 seconds")
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(20)) { [weak self] in
                    self?.turnOffTunnel()
                }
            }
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

extension AppDelegate {

    // Assumptions:
    //   - We just need one tunnel in iOS Settings / macOS Preferences for the app.
    //     We can reuse that with different configs if required.
    //   - The tunnel shall not be started from iOS Settings / macOS Preferences.
    //     It has to be started using the container app only.
    //   - The tunnel need not be configured to start automatically under
    //     certain conditions using on-demand

    func turnOnTunnel(completionHandler: @escaping (Bool) -> Void) {
        // We use loadAllFromPreferences to see if this app has already added a tunnel
        // to iOS Settings or (macOS Preferences)
        NETunnelProviderManager.loadAllFromPreferences { tunnelManagersInSettings, error in
            if let error = error {
                NSLog("Error (loadAllFromPreferences): \(error)")
                completionHandler(false)
                return
            }

            // If the app has already added a tunnel to Settings, we are going to modify that.
            // If not, we create a new instance and save that to Settings.
            // We will always have either 0 or 1 tunnel only in Settings for this app.
            let preExistingTunnelManager = tunnelManagersInSettings?.first
            let tunnelManager = preExistingTunnelManager ?? NETunnelProviderManager()

            // Configure the custom VPN protocol
            let protocolConfiguration = NETunnelProviderProtocol()

            // Set the tunnel extension's bundle id
            protocolConfiguration.providerBundleIdentifier = "<bundle-id-of-tunnel-extension>"

            // Set the server address as a non-nil string.
            // It would be good to provide the server's domain name or IP address.
            protocolConfiguration.serverAddress = "server"

            tunnelManager.protocolConfiguration = protocolConfiguration
            tunnelManager.isEnabled = true

            // Save the tunnel to preferences.
            // This would modify the existing tunnel, or create a new one.
            tunnelManager.saveToPreferences { error in
                if let error = error {
                    NSLog("Error (saveToPreferences): \(error)")
                    completionHandler(false)
                    return
                }
                // Load it back so we have a valid usable instance.
                tunnelManager.loadFromPreferences { error in
                    if let error = error {
                        NSLog("Error (loadFromPreferences): \(error)")
                        completionHandler(false)
                        return
                    }

                    // At this point, the tunnel is configured.
                    // Attempt to start the tunnel
                    do {
                        NSLog("Starting the tunnel")
                        guard let session = tunnelManager.connection as? NETunnelProviderSession else {
                            fatalError("tunnelManager.connection is invalid")
                        }
                        try session.startTunnel()
                    } catch {
                        NSLog("Error (startTunnel): \(error)")
                        completionHandler(false)
                    }
                    completionHandler(true)
                }
            }
        }
    }

    func turnOffTunnel() {
        NETunnelProviderManager.loadAllFromPreferences { tunnelManagersInSettings, error in
            if let error = error {
                NSLog("Error (loadAllFromPreferences): \(error)")
                return
            }
            if let tunnelManager = tunnelManagersInSettings?.first {
                guard let session = tunnelManager.connection as? NETunnelProviderSession else {
                    fatalError("tunnelManager.connection is invalid")
                }
                switch session.status {
                case .connected, .connecting, .reasserting:
                    NSLog("Stopping the tunnel")
                    session.stopTunnel()
                default:
                    break
                }
            }
        }
    }
}
