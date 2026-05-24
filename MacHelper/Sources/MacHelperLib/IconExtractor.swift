import Foundation

// MARK: - Data Models (Spec-04 §2)

/// 앱 아이콘 모델 (Spec-04 §2)
/// - appName: 앱 이름 (WindowInfo.app과 동일, 매칭 키)
/// - iconData: PNG base64 인코딩 문자열
public struct AppIcon: Codable, Equatable {
    public let appName: String
    public let iconData: String

    public init(appName: String, iconData: String) {
        self.appName = appName
        self.iconData = iconData
    }
}

/// 앱 아이콘 응답 모델 (Spec-04 §3)
/// { "type":"appIcons", "icons":{ "Arc":"base64...", "Xcode":"base64..." } }
public struct AppIconsResponse: Codable, Equatable {
    public let type: String
    public let icons: [String: String]

    public init(icons: [String: String]) {
        self.type = "appIcons"
        self.icons = icons
    }
}

// MARK: - Icon Cache (pure Swift, testable)

/// 앱별 아이콘 캐시 — 앱 이름 기준 중복 추출 방지 (Spec-04 §9 #1, #2)
public final class IconCache {
    private var cache: [String: String] = [:]

    public init() {}

    /// 캐시에 아이콘이 있는지 확인
    public func has(_ appName: String) -> Bool {
        return cache[appName] != nil
    }

    /// 캐시에 아이콘 저장
    public func set(_ appName: String, iconData: String) {
        cache[appName] = iconData
    }

    /// 캐시에서 아이콘 가져오기
    public func get(_ appName: String) -> String? {
        return cache[appName]
    }

    /// 새 앱 이름 목록에서 캐시에 없는 것만 필터링 (Spec-04 §4: 새 앱 감지)
    public func filterNew(_ appNames: [String]) -> [String] {
        return appNames.filter { !has($0) }
    }

    /// 중복 제거된 앱 이름 목록 추출 (WindowInfo 배열에서)
    /// 같은 앱 창 여러 개 → 앱 이름 1개만 (Spec-04 §9 #1)
    public static func uniqueAppNames(from windows: [WindowInfo]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for window in windows {
            if !seen.contains(window.app) {
                seen.insert(window.app)
                result.append(window.app)
            }
        }
        return result
    }

    /// 현재 캐시의 모든 아이콘을 AppIconsResponse로 변환
    public func toResponse() -> AppIconsResponse {
        return AppIconsResponse(icons: cache)
    }

    /// 특정 앱들의 아이콘만 AppIconsResponse로 변환 (새 앱 아이콘만 전송용)
    public func toResponse(for appNames: [String]) -> AppIconsResponse {
        var icons: [String: String] = [:]
        for name in appNames {
            if let data = cache[name] {
                icons[name] = data
            }
        }
        return AppIconsResponse(icons: icons)
    }

    /// 캐시 항목 수
    public var count: Int {
        return cache.count
    }
}

// MARK: - Base64 encoding helper (pure Swift)

/// PNG 데이터를 base64 문자열로 인코딩
public func encodeToBase64(_ data: Data) -> String {
    return data.base64EncodedString()
}

/// base64 문자열이 유효한 PNG인지 확인
/// PNG 시그니처: 89 50 4E 47 0D 0A 1A 0A
public func isValidPNGBase64(_ base64String: String) -> Bool {
    guard let data = Data(base64Encoded: base64String) else {
        return false
    }
    // PNG 시그니처 확인 (최소 8바이트)
    let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    guard data.count >= 8 else { return false }
    let header = Array(data.prefix(8))
    return header == pngSignature
}

// MARK: - Default icon (fallback)

/// 기본 아이콘 base64 (Spec-04 §5 ICON_NOT_FOUND)
/// 1x1 투명 PNG (최소 크기 fallback)
public let defaultIconBase64: String = {
    // 최소 1x1 투명 PNG 바이너리
    let pngBytes: [UInt8] = [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,  // PNG signature
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,  // IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,  // 1x1
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,  // 8bit RGBA
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,  // IDAT chunk
        0x54, 0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x02,  // compressed
        0x00, 0x01, 0xE5, 0x27, 0xDE, 0xFC, 0x00, 0x00,  // data
        0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,  // IEND chunk
        0x60, 0x82
    ]
    return Data(pngBytes).base64EncodedString()
}()

// MARK: - IconExtractor (macOS implementation)

#if canImport(AppKit)
import AppKit

/// 앱 아이콘 추출기 (macOS 전용)
public enum IconExtractor {

    /// 아이콘 리사이즈 크기 (Spec-04 §9 #3, Work-04 Task 3)
    public static let iconSize: CGFloat = 64.0

    /// PID로 앱 아이콘 추출 (Task 1)
    /// NSRunningApplication(processIdentifier: pid)?.icon
    /// 실패 시 nil 반환
    public static func extractIcon(pid: Int32) -> NSImage? {
        guard let app = NSRunningApplication(processIdentifier: pid) else {
            return nil
        }
        return app.icon
    }

    /// 번들 경로로 앱 아이콘 추출 (fallback, Spec-04 §7 분기 플로우)
    /// NSWorkspace.shared.icon(forFile: bundlePath)
    public static func extractIcon(bundlePath: String) -> NSImage {
        return NSWorkspace.shared.icon(forFile: bundlePath)
    }

    /// NSImage → 리사이즈된 PNG Data (Task 2 + 3)
    /// 64x64로 리사이즈 후 PNG 인코딩
    public static func resizeAndEncodePNG(_ image: NSImage) -> Data? {
        let size = NSSize(width: iconSize, height: iconSize)

        // 새 이미지를 target 크기로 생성
        let resizedImage = NSImage(size: size)
        resizedImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(
            in: NSRect(origin: .zero, size: size),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )
        resizedImage.unlockFocus()

        // NSImage → tiffRepresentation → NSBitmapImageRep → PNG
        guard let tiff = resizedImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }
        return pngData
    }

    /// PID로 아이콘 추출 → base64 인코딩 (전체 파이프라인)
    /// 실패 시 기본 아이콘 반환 (Spec-04 §5 ICON_NOT_FOUND)
    public static func extractIconBase64(pid: Int32) -> String {
        // Step 1: PID로 아이콘 추출 시도
        if let image = extractIcon(pid: pid),
           let pngData = resizeAndEncodePNG(image) {
            return encodeToBase64(pngData)
        }

        // Step 2: PID로 실패 시, 번들 경로로 시도 (Spec-04 §7)
        if let app = NSRunningApplication(processIdentifier: pid),
           let bundleURL = app.bundleURL {
            let image = extractIcon(bundlePath: bundleURL.path)
            if let pngData = resizeAndEncodePNG(image) {
                return encodeToBase64(pngData)
            }
        }

        // Step 3: 모두 실패 → 기본 아이콘 (Spec-04 §5)
        return defaultIconBase64
    }

    /// WindowInfo 배열에서 새 앱들의 아이콘을 추출하고 캐시에 저장
    /// - Returns: 새로 추출된 앱 이름 목록
    public static func extractIcons(
        from windows: [WindowInfo],
        cache: IconCache
    ) -> [String] {
        // 중복 제거된 앱 이름 추출 (Spec-04 §9 #1)
        let allApps = IconCache.uniqueAppNames(from: windows)

        // 캐시에 없는 새 앱만 필터 (Spec-04 §4, §9 #2)
        let newApps = cache.filterNew(allApps)

        // 새 앱들의 아이콘 추출
        for appName in newApps {
            // 해당 앱의 PID 찾기
            if let window = windows.first(where: { $0.app == appName }) {
                let base64 = extractIconBase64(pid: Int32(window.pid))
                cache.set(appName, iconData: base64)
            }
        }

        return newApps
    }
}
#endif
