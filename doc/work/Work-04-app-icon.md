# Work-04: M4 — 앱 아이콘 추출

| 항목 | 내용 |
|------|------|
| ID | Work-04 |
| 상태 | Backlog |
| 담당 | |
| 시작일 | |
| 완료일 | |
| 의존 | Work-01 |
| 관련 스펙 | Spec-04 |

## 1. 목표

> 실행 중 앱들의 아이콘을 PNG base64로 추출하는 함수를 만든다. 화면 캡처가 아닌 설치된 앱의 아이콘 파일을 읽는 것.

---

## 2. 참조 스펙 체크리스트

| Spec 섹션 | 항목 | 반영 여부 |
|-----------|------|-----------|
| Spec-04 §2 데이터 모델 | AppIcon (appName, iconData) | [ ] |
| Spec-04 §4 상태 전이 | 아이콘 추출 → base64 인코딩 | [ ] |
| Spec-04 §5 에러 처리 | ICON_NOT_FOUND → 기본 아이콘 대체 | [ ] |
| Spec-04 §9 엣지 케이스 | 아이콘 리사이즈, CLI 도구 | [ ] |

---

## 3. 태스크

| # | 태스크 | 상태 | 커밋 | 비고 |
|---|--------|------|------|------|
| 1 | NSRunningApplication.icon으로 아이콘 추출 | [ ] | | |
| 2 | NSImage → PNG Data → base64 인코딩 | [ ] | | |
| 3 | 아이콘 리사이즈 (64x64) | [ ] | | 전송 크기 최적화 |
| 4 | 실패 시 기본 아이콘 fallback | [ ] | | |
| 5 | 앱별 중복 제거 (이름 기준 1회) | [ ] | | |

---

## 4. 기술 메모

> - NSRunningApplication(processIdentifier: pid)?.icon → NSImage
> - fallback: NSWorkspace.shared.icon(forFile: bundlePath)
> - NSImage → tiffRepresentation → NSBitmapImageRep → png → base64

---

## 5. 검증 방법

| # | 검증 항목 | 방법 | 결과 |
|---|----------|------|------|
| 1 | 아이콘 추출 | `swift run MacHelper icons` → 앱별 base64 문자열 출력 | — |
| 2 | base64 검증 | 출력된 base64를 디코딩해 PNG 이미지인지 확인 | — |
| 3 | 중복 없음 | 같은 앱이 2번 이상 출력되지 않는지 확인 | — |

---

## 6. 변경 이력

| 날짜 | 변경 내용 | 작성자 |
|------|-----------|--------|
| 2026-05-24 | 최초 작성 | |
