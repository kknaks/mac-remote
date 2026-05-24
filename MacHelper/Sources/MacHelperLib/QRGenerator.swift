import Foundation

#if canImport(CoreImage)
import CoreImage
#endif

#if canImport(AppKit)
import AppKit
#endif

// MARK: - ConnectionInfo (Spec-07 §2)

/// 페어링 연결 정보 모델
/// host: Mac 헬퍼 IP 주소, port: WebSocket 포트
public struct ConnectionInfo: Codable, Equatable {
    public let host: String
    public let port: UInt16

    public init(host: String, port: UInt16) {
        self.host = host
        self.port = port
    }

    /// QR 코드에 인코딩할 WebSocket URL (Spec-07 §2: ws://{host}:{port})
    public var webSocketURL: String {
        return "\(qrPrefix)\(host):\(port)"
    }

    /// QR 페이로드를 UTF-8 Data로 변환
    public var qrPayloadData: Data? {
        return webSocketURL.data(using: .utf8)
    }
}

/// QR 페이로드 prefix (Spec-07 §3-2)
public let qrPrefix = "ws://"

// MARK: - QRGenerator (Work-07 Task 2)

/// QR 코드 생성기 — CIFilter("CIQRCodeGenerator") 사용
/// macOS에서만 실제 이미지 생성, Linux에서는 구조만 유지
public enum QRGenerator {

    /// 현재 Mac의 ConnectionInfo 생성
    /// NetworkInfo에서 IP를 가져오고 지정 포트로 ConnectionInfo 구성
    public static func currentConnectionInfo(port: UInt16 = defaultPort) -> ConnectionInfo {
        let ip = NetworkInfo.primaryIPAddress()
        return ConnectionInfo(host: ip, port: port)
    }

    #if canImport(CoreImage)
    /// QR 코드 CIImage 생성 (Spec-07 §4, Work-07 Task 2)
    /// - Parameter connectionInfo: 인코딩할 연결 정보
    /// - Returns: QR 코드 CIImage, 생성 실패 시 nil
    public static func generateQRImage(for connectionInfo: ConnectionInfo) -> CIImage? {
        guard let data = connectionInfo.qrPayloadData else { return nil }

        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel") // Medium 오류 보정

        return filter.outputImage
    }

    /// QR 코드 CIImage를 지정 크기로 스케일링
    /// - Parameters:
    ///   - image: 원본 QR CIImage
    ///   - size: 목표 크기 (포인트)
    /// - Returns: 스케일된 CIImage
    public static func scaleQRImage(_ image: CIImage, to size: CGFloat) -> CIImage {
        let extent = image.extent
        let scaleX = size / extent.width
        let scaleY = size / extent.height
        return image.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
    }
    #endif

    #if canImport(AppKit) && canImport(CoreImage)
    /// QR 코드를 NSImage로 생성 (메뉴바 팝오버 표시용)
    /// CIImage → NSBitmapImageRep → NSImage 변환
    /// - Parameters:
    ///   - connectionInfo: 인코딩할 연결 정보
    ///   - size: 이미지 크기 (기본 200pt)
    /// - Returns: QR 코드 NSImage, 생성 실패 시 nil
    public static func generateNSImage(
        for connectionInfo: ConnectionInfo,
        size: CGFloat = 200
    ) -> NSImage? {
        guard let ciImage = generateQRImage(for: connectionInfo) else { return nil }
        let scaled = scaleQRImage(ciImage, to: size)

        let rep = NSCIImageRep(ciImage: scaled)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }
    #endif

    /// QR 이미지 기본 크기 (포인트)
    public static let defaultQRSize: CGFloat = 200
}
