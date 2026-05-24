# Spec Index

> 모든 상세 스펙의 인덱스. 스펙 간 관계와 현황을 한눈에 파악한다.

## Spec Map

| ID | 제목 | 상태 | 의존 | 비고 |
|----|------|------|------|------|
| Spec-01 | 창 목록 수집 | Approved | — | CGWindowListCopyWindowInfo 기반 |
| Spec-02 | 창 활성화 | Approved | Spec-01 | PID + AXUIElement |
| Spec-03 | 키 입력 (매크로) | Approved | — | CGEvent 기반 |
| Spec-04 | 앱 아이콘 수집 | Approved | Spec-01 | NSWorkspace, 화면 캡처 아님 |
| Spec-05 | WebSocket 통신 프로토콜 | Approved | Spec-01, Spec-02, Spec-03, Spec-04 | JSON over WebSocket |
| Spec-06 | 권한 관리 | Approved | — | Accessibility + Screen Recording |
| Spec-07 | 페어링 | Approved | Spec-05 | QR 코드 + 수동 IP 입력 |

### 의존 관계 다이어그램

```
Spec-01 (창 목록) ──► Spec-02 (창 활성화)
    │                     │
    ├──► Spec-04 (앱 아이콘)
    │                     │
    └────┬────┬───────────┘
         ▼    ▼
Spec-03 (키 입력)    Spec-05 (WebSocket 프로토콜)
                         │
Spec-06 (권한) ◄─────────┤
                         │
                    Spec-07 (페어링)
```

## 상태 정의

| 상태 | 의미 |
|------|------|
| Draft | 작성 중 |
| Review | 리뷰 대기 |
| Approved | 확정, 구현 가능 |
| Done | 구현 완료 |
| Deprecated | 폐기 (사유 비고에 기록) |

## 변경 이력

| 날짜 | 변경 내용 |
|------|-----------|
| 2026-05-24 | 최초 작성 — 7개 스펙 등록 |
