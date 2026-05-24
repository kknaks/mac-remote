import SwiftUI
import AVFoundation

// MARK: - QR Scanner View (Spec-07 §8, Work-12 Task 1)

/// QR 코드 스캔 화면
/// AVCaptureSession으로 카메라 프리뷰를 표시하고 QR 코드를 자동 인식한다.
/// 인식 성공 시 onScan 콜백으로 페이로드 문자열을 전달한다.
struct QRScannerView: View {
    /// QR 인식 성공 시 호출되는 콜백 (페이로드 문자열)
    let onScan: (String) -> Void

    /// 화면 닫기
    @Environment(\.dismiss) private var dismiss

    /// 카메라 권한 상태
    @State private var cameraPermission: AVAuthorizationStatus = .notDetermined

    /// 에러 메시지
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                switch cameraPermission {
                case .authorized:
                    // 카메라 프리뷰 + QR 인식
                    CameraPreviewRepresentable(onScan: handleScanResult)
                        .ignoresSafeArea()

                    // 가이드 오버레이
                    scanGuideOverlay

                case .denied, .restricted:
                    // 카메라 권한 거부됨 (Spec-07 §5: CAMERA_DENIED)
                    cameraDeniedView

                case .notDetermined:
                    // 권한 요청 전
                    ProgressView("카메라 권한 요청 중...")
                        .foregroundStyle(.white)

                @unknown default:
                    cameraDeniedView
                }

                // 에러 메시지 오버레이
                if let errorMessage = errorMessage {
                    VStack {
                        Spacer()
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundStyle(.white)
                            .padding()
                            .background(.red.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding()
                    }
                }
            }
            .navigationTitle("QR 스캔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                    .foregroundStyle(Color.accent)
                }
            }
            .onAppear {
                checkCameraPermission()
            }
        }
    }

    // MARK: - Subviews

    /// 스캔 가이드 오버레이 (사각형 프레임)
    private var scanGuideOverlay: some View {
        VStack(spacing: 20) {
            Spacer()

            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.accent, lineWidth: 3)
                .frame(width: 250, height: 250)

            Text("QR 코드를 프레임 안에 맞춰주세요")
                .font(.callout)
                .foregroundStyle(.white)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.black.opacity(0.6))
                .clipShape(Capsule())

            Spacer()
                .frame(height: 100)
        }
    }

    /// 카메라 권한 거부 시 안내 화면
    private var cameraDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("카메라 권한이 필요합니다")
                .font(.title3)
                .foregroundStyle(.primary)

            // Spec-07 §5: CAMERA_DENIED 메시지
            Text("QR 스캔을 위해 카메라 권한이 필요합니다.\n설정에서 카메라 접근을 허용해주세요.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("설정 열기") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.accent)

            Button("닫기") {
                dismiss()
            }
            .foregroundStyle(.secondary)
        }
        .padding()
    }

    // MARK: - Camera Permission

    /// 카메라 권한 확인 및 요청
    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        cameraPermission = status

        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraPermission = granted ? .authorized : .denied
                }
            }
        }
    }

    /// QR 스캔 결과 처리
    private func handleScanResult(_ payload: String) {
        onScan(payload)
        dismiss()
    }
}

// MARK: - Camera Preview (UIViewRepresentable)

/// AVCaptureSession 기반 카메라 프리뷰
/// UIViewRepresentable로 SwiftUI에 임베드
struct CameraPreviewRepresentable: UIViewRepresentable {
    let onScan: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.delegate = context.coordinator
        view.startSession()
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // No update needed
    }

    /// AVCaptureMetadataOutputObjectsDelegate 코디네이터
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let onScan: (String) -> Void
        private var hasScanned = false

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            // 중복 스캔 방지
            guard !hasScanned else { return }

            guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  metadataObject.type == .qr,
                  let payload = metadataObject.stringValue else {
                return
            }

            hasScanned = true

            DispatchQueue.main.async { [weak self] in
                self?.onScan(payload)
            }
        }
    }
}

/// AVCaptureSession 카메라 프리뷰 UIView
class CameraPreviewUIView: UIView {
    weak var delegate: AVCaptureMetadataOutputObjectsDelegate?

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    func startSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(delegate, queue: .main)
            metadataOutput.metadataObjectTypes = [.qr]
        }

        let preview = AVCaptureVideoPreviewLayer(session: captureSession)
        preview.videoGravity = .resizeAspectFill
        preview.frame = bounds
        layer.addSublayer(preview)
        previewLayer = preview

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }

    func stopSession() {
        captureSession.stopRunning()
    }
}

#Preview {
    QRScannerView { payload in
        print("Scanned: \(payload)")
    }
    .preferredColorScheme(.dark)
}
