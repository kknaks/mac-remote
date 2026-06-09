import Foundation

#if canImport(Network)
import Network
#endif

// MARK: - NetworkInfo (Work-06 Task 3)

/// 로컬 네트워크 IP 주소 조회
/// iOS 앱이 연결할 Mac의 IP:포트를 메뉴바에 표시하기 위해 사용
public enum NetworkInfo {

    /// 로컬 Wi-Fi IP 주소 목록 조회 (인터페이스 이름과 함께)
    /// getifaddrs로 네트워크 인터페이스 목록을 가져온다.
    /// link-local(169.254.x), loopback은 제외한다.
    public static func localIPAddressesWithInterface() -> [(interface: String, address: String)] {
        var addresses: [(interface: String, address: String)] = []

        #if canImport(Darwin)
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return addresses
        }
        defer { freeifaddrs(ifaddr) }

        var ptr = firstAddr
        while true {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            // IPv4만 (AF_INET)
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                // en0 = Wi-Fi, en1+ = Ethernet/Thunderbolt, bridgeN = 인터넷 공유
                if name.hasPrefix("en") || name.hasPrefix("bridge") {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(
                        interface.ifa_addr,
                        socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil, 0,
                        NI_NUMERICHOST
                    ) == 0 {
                        let address = String(cString: hostname)
                        // link-local(169.254.x) 제외 — DHCP 실패 시 자동 부여되는 무효 주소
                        if !address.hasPrefix("169.254.") {
                            addresses.append((name, address))
                        }
                    }
                }
            }

            guard let next = interface.ifa_next else { break }
            ptr = next
        }
        #endif

        return addresses
    }

    /// 로컬 Wi-Fi IP 주소 목록 (인터페이스 이름 없이 — 기존 API 호환)
    public static func localIPAddresses() -> [String] {
        return localIPAddressesWithInterface().map { $0.address }
    }

    /// 대표 IP 주소 — en0(Wi-Fi) 우선, 그다음 bridge(인터넷 공유), 그다음 다른 en*
    /// 모두 없으면 "localhost"
    public static func primaryIPAddress() -> String {
        let all = localIPAddressesWithInterface()
        if let wifi = all.first(where: { $0.interface == "en0" }) {
            return wifi.address
        }
        if let shared = all.first(where: { $0.interface.hasPrefix("bridge") }) {
            return shared.address
        }
        return all.first?.address ?? "localhost"
    }
}

// MARK: - IPMonitor (Work-07 Task 4)

/// IP 주소 변경 감지 — NWPathMonitor 사용
/// 네트워크 경로가 바뀌면 콜백을 호출해 QR 코드를 갱신한다.
/// Spec-07 §9: IP 변경 시 QR 갱신
public final class IPMonitor {

    /// 현재 감지된 IP 주소
    public private(set) var currentIP: String

    /// IP 변경 시 호출되는 콜백
    public var onIPChanged: ((String) -> Void)?

    #if canImport(Network)
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.machelper.ipmonitor")
    #endif

    public init() {
        self.currentIP = NetworkInfo.primaryIPAddress()
    }

    /// 모니터링 시작
    public func start() {
        #if canImport(Network)
        monitor.pathUpdateHandler = { [weak self] _ in
            self?.checkIPChange()
        }
        monitor.start(queue: queue)
        #endif
    }

    /// 모니터링 정지
    public func stop() {
        #if canImport(Network)
        monitor.cancel()
        #endif
    }

    /// IP 변경 확인 — 변경 시 콜백 호출
    /// 외부에서 수동으로 호출 가능 (테스트용)
    public func checkIPChange() {
        let newIP = NetworkInfo.primaryIPAddress()
        if newIP != currentIP {
            let oldIP = currentIP
            currentIP = newIP
            print("[INFO] IP changed: \(oldIP) → \(newIP)")
            onIPChanged?(newIP)
        }
    }

    /// 테스트용: 현재 IP를 강제로 설정 (변경 감지 테스트)
    internal func _setCurrentIP(_ ip: String) {
        currentIP = ip
    }
}
