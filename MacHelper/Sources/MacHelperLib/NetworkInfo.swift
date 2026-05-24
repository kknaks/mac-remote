import Foundation

// MARK: - NetworkInfo (Work-06 Task 3)

/// 로컬 네트워크 IP 주소 조회
/// iOS 앱이 연결할 Mac의 IP:포트를 메뉴바에 표시하기 위해 사용
public enum NetworkInfo {

    /// 로컬 Wi-Fi IP 주소 목록 조회
    /// getifaddrs로 네트워크 인터페이스 목록을 가져온다.
    /// en0 (Wi-Fi) 우선, 없으면 다른 인터페이스도 포함
    public static func localIPAddresses() -> [String] {
        var addresses: [String] = []

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
                // en0 = Wi-Fi, en1 = Ethernet (일반적)
                if name.hasPrefix("en") {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(
                        interface.ifa_addr,
                        socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil, 0,
                        NI_NUMERICHOST
                    ) == 0 {
                        addresses.append(String(cString: hostname))
                    }
                }
            }

            guard let next = interface.ifa_next else { break }
            ptr = next
        }
        #endif

        return addresses
    }

    /// 대표 IP 주소 (첫 번째, 없으면 "localhost")
    public static func primaryIPAddress() -> String {
        return localIPAddresses().first ?? "localhost"
    }
}
