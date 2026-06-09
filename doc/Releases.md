# Releases

프로젝트 릴리즈 노트. 최신 버전이 맨 위.

각 항목은 사용자 관점의 변화(증상 → 수정)와 변경 파일을 함께 적는다.
배포 절차 자체는 `doc/runbook/` 참조.

---

## 1.0.1 — 2026-05-26

회사 Wi-Fi 같은 단말 격리 환경에서 페어링/재연결이 실패하던 문제 + 메뉴바 IP가 stale하게 표시되던 문제 + 재연결 후 창 목록에 아이콘이 안 나오던 문제를 함께 수정.

### Fixed

- **Mac 메뉴바 QR이 옛 IP를 계속 표시** — 네트워크 전환(집 → 회사, Wi-Fi → 핫스팟 등) 후에도 처음 띄울 때 잡힌 IP가 그대로 굳어 있었음. 앱을 껐다 켜야 갱신됐다.
  - 원인: `QRCodeView.@State currentIP`가 뷰 init 시점에만 평가되고, MenuBarExtra가 뷰 인스턴스를 재사용하기 때문에 onAppear 때 재조회되지 않았음.
  - 수정: `MacHelper/Sources/MacHelperLib/MenuBarApp.swift` — `onAppear`에서 `currentIP = NetworkInfo.primaryIPAddress()`로 매번 재조회.

- **여러 네트워크 인터페이스 활성 시 잘못된 IP 선택 가능** — `en0`(Wi-Fi)이 아닌 다른 `en*` 또는 link-local(`169.254.x`)이 잡힐 위험이 있었음.
  - 수정: `MacHelper/Sources/MacHelperLib/NetworkInfo.swift` — `primaryIPAddress()`가 **en0(Wi-Fi) → bridge*(인터넷 공유) → 기타** 순서로 우선 선택하고 link-local은 제외.

- **iOS에서 QR 다시 스캔/IP 수동 입력해도 옛 호스트로 계속 재연결 시도** — "재연결 중"이 매우 오래 걸리거나 안정화 후 옛 IP의 폴백 시도가 계속 끼어들었음.
  - 원인: `WebSocketManager.connect()`의 가드가 `.connected/.connecting` 상태에서 빠져나가고, 진행 중이던 `webSocketTask`와 `reconnectTimer`를 정리하지 않은 채 새 호스트로 연결을 시도했음.
  - 수정:
    - `iOSApp/iOSApp/WebSocketManager.swift` — 새 메서드 `reconnect(host:port:)` 추가. 기존 task/timer를 동기 정리하고 상태를 `.disconnected`로 만든 뒤 `connect()`.
    - `iOSApp/iOSApp/Views/SettingsView.swift` — `handleQRScan()`, `connectManually()`가 `connect` 대신 `reconnect` 사용.

- **재연결한 iPhone 창 목록에 앱 아이콘이 표시되지 않음** — 회사에서 재연결하면 창 카드는 뜨는데 아이콘이 비어 있었음.
  - 원인: Mac의 `pushNewAppIcons()`가 "서버 캐시에 없는 새 앱"만 전송. 서버가 계속 켜져있어서 캐시가 이미 차 있으면 새 클라이언트에게 아무것도 안 보냄. iPhone의 in-memory 아이콘 dict는 재연결 시점에 비어있었음.
  - 수정: `MacHelper/Sources/MacHelperLib/WebSocketServer.swift` — `handleConnect()`에서 새 메서드 `sendFullIconSnapshot(to:)`을 호출해 전체 아이콘 캐시를 신규 클라이언트에게 1회 push.

### Added

- **iOS: 연결 중 화면 자동 잠금 차단** — WebSocket이 `.connected` 동안만 `UIApplication.shared.isIdleTimerDisabled = true`로 화면을 켜둔다. 끊기면 자동으로 시스템 자동 잠금 복귀.
  - 이유: 리모컨 사용 중 화면이 꺼지면 매번 잠금 해제 필요해서 사용성이 떨어졌음.
  - 수정: `iOSApp/iOSApp/ContentView.swift` — `updateIdleTimer()` 메서드 추가, `connectionState` `.onChange` + `.onAppear`에서 호출.
  - iOS 빌드 번호: 2 → 3 (Mac은 변경 없음, 그대로 빌드 2)

### 알려진 미수정 사항

- iOS `WebSocketManager.connect()`가 핸드셰이크 성공 확인 없이 `DispatchQueue.main.async`로 즉시 `.connected`로 상태 변경 (WebSocketManager.swift:190-199). 실제 연결 실패 시에도 "연결됨"이 잠깐 보였다가 receive 실패로 reconnect 루프 진입. 디버깅이 헷갈리는 원인이라 다음 패치 후보.
- 회사 Wi-Fi의 client isolation/AP isolation 자체는 앱 수정으로 우회 불가. Mac "인터넷 공유"로 Mac이 핫스팟이 되어 iPhone을 직결시키는 방식이 가장 안정적인 회피책.

### 검증

- `swift test --filter "NetworkInfo|WebSocketServer|IconExtractor"` — 통과
- `swift build -c release` — 성공
- `xcodebuild -scheme MacRemote -destination 'generic/platform=iOS' -configuration Debug build` — 성공
- 사전 존재하던 `MessageHandlerTests` 일부 실패(테스트 환경 Accessibility 권한 부재 원인)는 본 변경과 무관

---

## 1.0.0 — 초기 릴리즈

- Mac 헬퍼: 메뉴바 앱, WebSocket 서버(포트 8765), 창 목록/포커스/키 입력, QR 페어링
- iOS 앱: 창 목록 탭, 매크로 탭, 설정 탭, QR 스캔, 자동 재연결
- 배포: Mac DMG (Developer ID 사인), iOS TestFlight


  xcrun notarytool store-credentials "AC_NOTARY" \
    --apple-id "benesia93@naver.com" \
    --team-id "UYQF47UCVR" \
    --password "wtlo-emsb-euyi-ngwp"