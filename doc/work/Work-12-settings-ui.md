# Work-12: I5 — 설정 화면

| 항목 | 내용 |
|------|------|
| ID | Work-12 |
| 상태 | Done |
| 담당 | |
| 시작일 | 2026-05-24 |
| 완료일 | 2026-05-24 |
| 의존 | Work-09 |
| 관련 스펙 | Spec-06, Spec-07 |

## 1. 목표

> QR 스캔 / 수동 IP 입력으로 페어링하고, 헬퍼 권한 상태를 표시하고, 앱 설정(햅틱/자동재연결/빈 제목 숨기기)을 관리한다.

---

## 2. 참조 스펙 체크리스트

| Spec 섹션 | 항목 | 반영 여부 |
|-----------|------|-----------|
| Spec-07 §4 상태 전이 | 미페어링→연결 시도→완료 | [x] |
| Spec-07 §5 에러 처리 | INVALID_QR, CONNECTION_FAIL, CAMERA_DENIED | [x] |
| Spec-07 §8 UI/UX | QR 스캔 버튼 + 수동 입력 | [x] |
| Spec-06 §8 UI/UX | 권한 상태 표시 (초록/빨강) | [x] |

---

## 3. 태스크

| # | 태스크 | 상태 | 커밋 | 비고 |
|---|--------|------|------|------|
| 1 | QR 스캔 뷰 (AVCaptureSession + 카메라) | [x] | f036345 | QRScannerView + CameraPreviewRepresentable |
| 2 | QR 페이로드 파싱 (ws://host:port) | [x] | 2c91b54 | ConnectionInfo.fromQRPayload + IPv4 검증 |
| 3 | 수동 IP:포트 입력 필드 + 연결 버튼 | [x] | 88da347 | SettingsView 전체 구현 (Form 기반) |
| 4 | ConnectionInfo UserDefaults 저장/로드 | [x] | 7a78338 | ConnectionInfoStore save/load/clear |
| 5 | 헬퍼 권한 상태 표시 (getPermissions 응답) | [x] | 1bd987c | StatusIndicator 3색 + PermissionBadge |
| 6 | 설정 토글 (햅틱/자동재연결/빈 제목 숨기기) | [x] | 14de46d | @AppStorage + AppSettings 헬퍼 |
| 7 | 앱 시작 시 저장된 정보로 자동 연결 | [x] | 45be79f | iOSAppApp.autoConnectIfNeeded |

---

## 4. 기술 메모

> - AVCaptureMetadataOutput으로 QR 인식
> - Info.plist에 NSCameraUsageDescription 필요
> - 카메라 권한 거부 시 수동 입력 fallback
> - StatusIndicator: ConnectionState 기반 녹/황/적 3색 표시
> - PermissionBadge: 권한 상태 초록(허용)/빨강(거부) 뱃지
> - AppSettings: UserDefaults 기반 앱 설정 (비-SwiftUI 코드에서도 접근 가능)

---

## 5. 검증 방법

| # | 검증 항목 | 방법 | 결과 |
|---|----------|------|------|
| 1 | QR 스캔 | Mac QR 표시 → iOS 스캔 → 자동 연결 | 수동 검증 (Xcode 필요) |
| 2 | 수동 입력 | IP:포트 입력 → 연결 성공 | 수동 검증 (Xcode 필요) |
| 3 | 자동 연결 | 앱 종료 후 재실행 → 저장된 정보로 연결 | 수동 검증 (Xcode 필요) |
| 4 | 권한 표시 | 설정 탭에서 Accessibility/Screen Recording 상태 확인 | 수동 검증 (Xcode 필요) |

---

## 6. 변경 이력

| 날짜 | 변경 내용 | 작성자 |
|------|-----------|--------|
| 2026-05-24 | 최초 작성 | |
| 2026-05-24 | 전체 태스크 구현 완료 (7/7) | |
