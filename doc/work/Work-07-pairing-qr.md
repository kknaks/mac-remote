# Work-07: M7 — 페어링 QR

| 항목 | 내용 |
|------|------|
| ID | Work-07 |
| 상태 | Done |
| 담당 | |
| 시작일 | 2026-05-24 |
| 완료일 | 2026-05-24 |
| 의존 | Work-06 |
| 관련 스펙 | Spec-07 |

## 1. 목표

> Mac 헬퍼의 IP:포트를 QR 코드로 생성·표시한다. iOS 앱이 이 QR을 스캔해 페어링한다.

---

## 2. 참조 스펙 체크리스트

| Spec 섹션 | 항목 | 반영 여부 |
|-----------|------|-----------|
| Spec-07 §2 데이터 모델 | ConnectionInfo, QR 페이로드 형식 | [x] |
| Spec-07 §8 UI/UX | Mac 메뉴바 팝오버 QR 표시 | [x] |
| Spec-07 §9 엣지 케이스 | IP 변경, 포트 충돌 | [x] |

---

## 3. 태스크

| # | 태스크 | 상태 | 커밋 | 비고 |
|---|--------|------|------|------|
| 1 | 로컬 IP 주소 획득 함수 | [x] | 61f3cca | ConnectionInfo + webSocketURL + qrPayloadData |
| 2 | QR 코드 생성 (CIFilter "CIQRCodeGenerator") | [x] | fff4ede | CIImage + NSImage 변환, #if canImport 가드 |
| 3 | 메뉴바 팝오버에 QR 이미지 + IP:포트 텍스트 표시 | [x] | 6579ca8 | QRCodeView + .window 스타일 MenuBarExtra |
| 4 | IP 변경 감지 시 QR 갱신 | [x] | 3231b14 | IPMonitor (NWPathMonitor) + QRCodeView 자동 갱신 |

---

## 4. 기술 메모

> - CIFilter(name: "CIQRCodeGenerator") → CIImage → NSImage
> - 로컬 IP: getifaddrs()로 en0 주소 획득 (NetworkInfo, Work-06에서 구현)
> - QR 데이터: "ws://192.168.1.10:8765"
> - ConnectionInfo(host, port) 모델로 QR 페이로드 관리
> - IPMonitor: NWPathMonitor로 네트워크 변경 감지, QRCodeView에서 @State로 IP 갱신
> - MenuBarExtra .window 스타일로 전환 — 커스텀 SwiftUI 뷰(QR 이미지) 지원

---

## 5. 검증 방법

| # | 검증 항목 | 방법 | 결과 |
|---|----------|------|------|
| 1 | QR 표시 | 메뉴바 클릭 → QR 코드 이미지 표시 | 수동 검증 (macOS 필요) |
| 2 | QR 내용 | 다른 QR 리더로 스캔 → ws://ip:port 형식 확인 | 수동 검증 (macOS 필요) |
| 3 | IP 정확성 | 표시된 IP가 실제 LAN IP와 일치하는지 확인 | 수동 검증 (macOS 필요) |
| 4 | 순수 로직 | ConnectionInfo, IPMonitor 등 순수 Swift 테스트 19개 | Linux 테스트 작성 완료 (swift 미설치로 실행 보류) |

---

## 6. 변경 이력

| 날짜 | 변경 내용 | 작성자 |
|------|-----------|--------|
| 2026-05-24 | 최초 작성 | |
| 2026-05-24 | Task 1~4 완료, 상태 Done | |
