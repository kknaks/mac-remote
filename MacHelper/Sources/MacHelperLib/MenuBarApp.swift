// MenuBarApp.swift — MenuBarExtra 메뉴바 뷰 (Work-06 Task 2, Work-07 Task 3)
// macOS 14+ SwiftUI 뷰 컴포넌트
// @main 엔트리 포인트는 MacHelperApp 타겟에 위치
// Linux에서는 컴파일 불가 — #if canImport(SwiftUI) 가드

#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI

// MARK: - MenuBarContentView (Work-06 Task 2, 3, 4 / Work-07 Task 3)

/// 메뉴바 팝오버 윈도우 내용 (.window 스타일)
/// QR 코드 이미지 + 연결 상태 + 권한 상태를 한 화면에 표시
@available(macOS 14.0, *)
public struct MenuBarContentView: View {
    let appState: AppState
    let onQuit: () -> Void
    let onOpenAccessibilitySettings: () -> Void
    let onOpenScreenRecordingSettings: () -> Void

    public init(
        appState: AppState,
        onQuit: @escaping () -> Void,
        onOpenAccessibilitySettings: @escaping () -> Void,
        onOpenScreenRecordingSettings: @escaping () -> Void
    ) {
        self.appState = appState
        self.onQuit = onQuit
        self.onOpenAccessibilitySettings = onOpenAccessibilitySettings
        self.onOpenScreenRecordingSettings = onOpenScreenRecordingSettings
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Work-07 Task 3: QR 코드 표시 (Spec-07 §8)
            QRCodeView(port: appState.serverPort)

            Divider()

            // 연결 상태 표시 (클라이언트 수, IP:포트)
            VStack(alignment: .leading, spacing: 4) {
                Label(appState.connectionStatusText, systemImage: "wifi")
                Text(appState.fullAddressText(ip: NetworkInfo.primaryIPAddress()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // 권한 상태 표시
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(appState.accessibilityStatusText)
                    Spacer()
                    if !appState.permissions.accessibility {
                        Button("설정 열기") {
                            onOpenAccessibilitySettings()
                        }
                        .controlSize(.small)
                    }
                }
                HStack {
                    Text(appState.screenRecordingStatusText)
                    Spacer()
                    if !appState.permissions.screenRecording {
                        Button("설정 열기") {
                            onOpenScreenRecordingSettings()
                        }
                        .controlSize(.small)
                    }
                }
            }

            Divider()

            // 종료 버튼
            Button("종료") {
                onQuit()
            }
            .keyboardShortcut("q")
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .frame(width: 280)
    }
}

// MARK: - QRCodeView (Work-07 Task 3, 4)

/// QR 코드 표시 뷰 — 메뉴바 팝오버 내부에 배치
/// ConnectionInfo에서 ws://IP:PORT QR 코드를 생성하여 표시한다.
/// IP 변경 감지 시 자동으로 QR 코드를 갱신한다. (Spec-07 §9)
@available(macOS 14.0, *)
public struct QRCodeView: View {
    let port: UInt16
    @State private var currentIP: String = NetworkInfo.primaryIPAddress()
    @State private var ipMonitor: IPMonitor?

    public init(port: UInt16) {
        self.port = port
    }

    private var connectionInfo: ConnectionInfo {
        ConnectionInfo(host: currentIP, port: port)
    }

    public var body: some View {
        VStack(spacing: 8) {
            Text("QR 코드로 페어링")
                .font(.headline)

            // QR 코드 이미지
            qrImageView
                .frame(width: QRGenerator.defaultQRSize, height: QRGenerator.defaultQRSize)
                .background(Color.white)
                .cornerRadius(8)

            // WebSocket URL 텍스트
            Text(connectionInfo.webSocketURL)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .onAppear {
            startIPMonitor()
        }
        .onDisappear {
            ipMonitor?.stop()
        }
    }

    @ViewBuilder
    private var qrImageView: some View {
        if let nsImage = QRGenerator.generateNSImage(
            for: connectionInfo, size: QRGenerator.defaultQRSize
        ) {
            Image(nsImage: nsImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            // QR 생성 실패 시 fallback
            VStack {
                Image(systemName: "qrcode")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                Text("QR 생성 실패")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// IP 변경 감지 모니터 시작 (Work-07 Task 4)
    private func startIPMonitor() {
        let monitor = IPMonitor()
        monitor.onIPChanged = { newIP in
            DispatchQueue.main.async {
                self.currentIP = newIP
            }
        }
        monitor.start()
        self.ipMonitor = monitor
    }
}
#endif
