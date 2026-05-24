import SwiftUI

/// 3탭 TabView 메인 화면
/// - 창 목록 (macwindow)
/// - 매크로 (command)
/// - 설정 (gearshape)
struct ContentView: View {
    var body: some View {
        TabView {
            WindowListView()
                .tabItem {
                    Label("창 목록", systemImage: "macwindow")
                }

            MacroView()
                .tabItem {
                    Label("매크로", systemImage: "command")
                }

            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "gearshape")
                }
        }
        .tint(Color.accent)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
