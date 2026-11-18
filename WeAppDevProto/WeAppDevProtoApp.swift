import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock: UIInterfaceOrientationMask = .all

    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        Self.orientationLock
    }
}

@main
struct WeAppDevProtoApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var gateway = GatewayServer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(gateway)
                .onAppear { gateway.start() }
                .onDisappear { gateway.stop() }
        }
    }
}
