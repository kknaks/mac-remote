import SwiftUI

// MARK: - Settings View (Spec-06 §8, Spec-07 §8, Work-12)

/// 설정 탭 — 연결 관리 + 권한 상태 + 앱 설정
struct SettingsView: View {
    @EnvironmentObject var wsManager: WebSocketManager

    /// 수동 IP 입력 필드
    @State private var ipInput: String = ""

    /// 수동 포트 입력 필드
    @State private var portInput: String = ""

    /// QR 스캐너 표시 여부
    @State private var showQRScanner: Bool = false

    /// 에러 메시지
    @State private var errorMessage: String?

    /// 에러 표시 여부
    @State private var showError: Bool = false

    /// 설정: 햅틱 피드백 (UserDefaults)
    @AppStorage("hapticEnabled") private var hapticEnabled: Bool = true

    /// 설정: 자동 재연결 (UserDefaults)
    @AppStorage("autoReconnect") private var autoReconnect: Bool = true

    /// 설정: 빈 제목 숨기기 (UserDefaults)
    @AppStorage("hideEmptyTitle") private var hideEmptyTitle: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 연결 상태 헤더 (Work-13 Task 3)
                ConnectionStatusHeader()

                Form {
                    // MARK: Section 1 — 연결 상태
                    connectionStatusSection

                    // MARK: Section 2 — 연결 설정 (QR 스캔 + 수동 입력)
                    connectionSection

                    // MARK: Section 3 — 헬퍼 권한 상태
                    permissionsSection

                    // MARK: Section 4 — 앱 설정
                    appSettingsSection

                    // MARK: Section 5 — 앱 정보
                    appInfoSection
                }
            }
            .navigationTitle("설정")
            .onAppear {
                loadSavedConnection()
            }
            .sheet(isPresented: $showQRScanner) {
                QRScannerView { payload in
                    handleQRScan(payload)
                }
            }
            .alert("오류", isPresented: $showError) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "알 수 없는 오류")
            }
        }
    }

    // MARK: - Section: 연결 상태

    private var connectionStatusSection: some View {
        Section {
            HStack {
                Text("상태")
                Spacer()
                StatusIndicator(state: wsManager.connectionState)
            }

            if wsManager.isConnected {
                HStack {
                    Text("서버")
                    Spacer()
                    Text(wsManager.host.isEmpty ? "-" : "\(wsManager.host):\(wsManager.port)")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("연결 상태")
        }
    }

    // MARK: - Section: 연결 설정 (Spec-07 §8)

    private var connectionSection: some View {
        Section {
            // QR 스캔 버튼 (Spec-07 §8)
            Button {
                showQRScanner = true
            } label: {
                Label("QR 코드 스캔", systemImage: "qrcode.viewfinder")
                    .foregroundStyle(Color.accent)
            }

            // 수동 IP:포트 입력 (Spec-07 §8)
            HStack {
                TextField("IP 주소", text: $ipInput)
                    .keyboardType(.decimalPad)
                    .textContentType(.URL)
                    .autocorrectionDisabled()

                Text(":")
                    .foregroundStyle(.secondary)

                TextField("포트", text: $portInput)
                    .keyboardType(.numberPad)
                    .frame(width: 60)
            }

            // 연결/해제 버튼
            if wsManager.isConnected || wsManager.isConnecting {
                Button(role: .destructive) {
                    wsManager.disconnect()
                } label: {
                    Label("연결 해제", systemImage: "xmark.circle")
                }
            } else {
                Button {
                    connectManually()
                } label: {
                    Label("연결", systemImage: "link")
                        .foregroundStyle(Color.accent)
                }
            }
        } header: {
            Text("연결 설정")
        } footer: {
            Text("Mac 헬퍼의 메뉴바에서 QR 코드를 표시하거나, IP 주소를 직접 입력하세요.")
        }
    }

    // MARK: - Section: 헬퍼 권한 상태 (Spec-06 §8)

    private var permissionsSection: some View {
        Section {
            if let permissions = wsManager.permissions {
                // Accessibility 권한 (Spec-06 §8: 초록/빨강)
                HStack {
                    Label("손쉬운 사용", systemImage: "accessibility")
                    Spacer()
                    PermissionBadge(granted: permissions.accessibility)
                }

                // Screen Recording 권한 (Spec-06 §8: 초록/빨강)
                HStack {
                    Label("화면 기록", systemImage: "record.circle")
                    Spacer()
                    PermissionBadge(granted: permissions.screenRecording)
                }
            } else if wsManager.isConnected {
                // 연결됨이지만 아직 권한 정보 없음 → 요청
                Button {
                    wsManager.sendGetPermissions()
                } label: {
                    Label("권한 상태 확인", systemImage: "arrow.clockwise")
                        .foregroundStyle(Color.accent)
                }
            } else {
                Text("Mac에 연결하면 권한 상태가 표시됩니다.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        } header: {
            Text("Mac 헬퍼 권한")
        } footer: {
            if let permissions = wsManager.permissions {
                if !permissions.accessibility {
                    Text("시스템 설정 → 개인 정보 보호 → 손쉬운 사용에서 허용해주세요")
                } else if !permissions.screenRecording {
                    Text("화면 기록 권한을 허용하면 창 제목이 표시됩니다")
                }
            }
        }
    }

    // MARK: - Section: 앱 설정 (Work-12 Task 6)

    private var appSettingsSection: some View {
        Section {
            Toggle(isOn: $hapticEnabled) {
                Label("햅틱 피드백", systemImage: "iphone.radiowaves.left.and.right")
            }

            Toggle(isOn: $autoReconnect) {
                Label("자동 재연결", systemImage: "arrow.triangle.2.circlepath")
            }

            Toggle(isOn: $hideEmptyTitle) {
                Label("빈 제목 숨기기", systemImage: "eye.slash")
            }
        } header: {
            Text("앱 설정")
        }
    }

    // MARK: - Section: 앱 정보

    private var appInfoSection: some View {
        Section {
            HStack {
                Text("버전")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("앱 정보")
        }
    }

    // MARK: - Actions

    /// 저장된 연결 정보 불러오기
    private func loadSavedConnection() {
        if let info = ConnectionInfoStore.load() {
            ipInput = info.host
            portInput = String(info.port)
        } else {
            portInput = String(wsDefaultPort)
        }

        // 연결됨 상태에서 권한 정보 요청 (Spec-06 §8)
        if wsManager.isConnected {
            wsManager.sendGetPermissions()
        }
    }

    /// 수동 IP:포트 입력으로 연결 (Spec-07 §8)
    private func connectManually() {
        let input = portInput.isEmpty ? ipInput : "\(ipInput):\(portInput)"

        guard let info = ConnectionInfo.fromManualInput(input) else {
            // Spec-07 §5: INVALID_IP
            errorMessage = PairingError.invalidIP.message
            showError = true
            return
        }

        // 연결 정보 저장 (Spec-07 §4: 성공 시 UserDefaults 저장)
        ConnectionInfoStore.save(info)
        ipInput = info.host
        portInput = String(info.port)

        wsManager.connect(host: info.host, port: info.port)
    }

    /// QR 스캔 결과 처리 (Spec-07 §4, §5)
    private func handleQRScan(_ payload: String) {
        guard let info = ConnectionInfo.fromQRPayload(payload) else {
            // Spec-07 §5: INVALID_QR
            errorMessage = PairingError.invalidQR.message
            showError = true
            return
        }

        // 입력 필드 업데이트
        ipInput = info.host
        portInput = String(info.port)

        // 연결 정보 저장 + 연결 (Spec-07 §4)
        ConnectionInfoStore.save(info)
        wsManager.connect(host: info.host, port: info.port)
    }
}

// MARK: - Permission Badge (Spec-06 §8)

/// 권한 상태 뱃지 (초록: 허용, 빨강: 거부)
struct PermissionBadge: View {
    let granted: Bool

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(granted ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(granted ? "허용됨" : "거부됨")
                .font(.caption)
                .foregroundStyle(granted ? .green : .red)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(WebSocketManager())
        .preferredColorScheme(.dark)
}
