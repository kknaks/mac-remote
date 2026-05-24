import SwiftUI

/// 앱 엔트리 포인트 (iOS 17+, SwiftUI)
@main
struct iOSAppApp: App {
    @StateObject private var wsManager = WebSocketManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(wsManager)
        }
    }
}
