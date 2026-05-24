# /doc-arch — 아키텍처 문서 작성

## 읽어야 할 파일 (이것만 읽는다)

1. `doc/templates/Architecture.tpl.md` — 템플릿
2. `doc/Decision.md` — 기술 선택·제약 확인
3. `doc/Spec.md` — 스펙 인덱스 (전체 기능 범위 파악, 상세 스펙은 필요 시만)
4. `doc/Architecture.md` — 기존 문서가 있으면 (업데이트 시)

## 만들어야 할 파일

- `doc/Architecture.md`

---

## 작성 규칙

1. 기술 스택(§1)은 Decision.md의 기술 선택 요약과 일치해야 한다. 불일치가 있으면 사용자에게 확인한다.
2. 전체 엔티티(§2)는 프로젝트 전반의 데이터 객체를 나열한다. 각 엔티티의 상세 정의는 관련 Spec에 있으므로 여기선 이름·설명·생명주기·저장 방식·참조 스펙만 기록한다.
3. 프로젝트 디렉토리 구조(§3)는 실제 파일 시스템과 일치해야 한다. `ls` 등으로 확인 후 작성한다.
4. 시스템 구조도(§4)는 ASCII 다이어그램으로 작성한다. 컴포넌트 간 화살표에 프로토콜/포맷을 표시한다.
5. 통신/인터페이스(§6)의 "참조 스펙" 열은 해당 계약이 정의된 스펙 문서의 섹션 번호까지 기록한다 (예: `Spec-05 §3`).
6. 배포/실행 환경(§8)에 필요한 권한과 설정을 빠짐없이 기록한다.

## 예제

### 기술 스택 예시

```markdown
| 계층 | 기술 | 버전 | 선택 근거 |
|------|------|------|-----------|
| Mac 헬퍼 | Swift, AppKit | 5.9+ / macOS 14+ | 네이티브 API 접근 필수 (CGEvent, AXUIElement) |
| iOS 앱 | Swift, SwiftUI | 5.9+ / iOS 17+ | 선언형 UI, URLSessionWebSocketTask 내장 |
| 통신 | WebSocket (JSON) | — | 실시간 양방향, 낮은 지연 |
| Mac WS 라이브러리 | Swifter | latest | 경량, 순수 Swift |
```

### 전체 엔티티 예시

```markdown
| WindowInfo | 창 정보 (id, app, title, pid, frontmost) | 런타임 | 메모리 | Spec-01 |
| MacroItem | 사용자 정의 매크로 (이름, key, modifiers) | 영속 | UserDefaults | Spec-04 |
| AppIcon | 앱 아이콘 (앱 이름, PNG base64) | 런타임+캐시 | 메모리 | Spec-03 |
```

### 디렉토리 구조 예시

```markdown
| MacHelper/ | Mac 헬퍼 앱 소스 | Swift Package |
| iOSApp/ | iOS 앱 소스 | Xcode 프로젝트 |
| doc/ | 프로젝트 문서 | 템플릿, 스펙, 워크 |
```

---

## 해야 하는 것 (DO)

- 실제 디렉토리 구조를 `ls`로 확인하고 §3을 작성한다.
- Decision.md의 기술 선택과 §1이 일치하는지 대조한다.
- 엔티티의 저장 방식을 명확히 구분한다 (메모리 / UserDefaults / 파일).
- 컴포넌트 간 통신은 참조 스펙 번호를 명시한다.
- 권한(Accessibility, Screen Recording 등)을 §8에 빠짐없이 기록한다.

## 하지 말아야 할 것 (DON'T)

- 엔티티의 필드 상세를 여기에 쓰지 않는다 — 그건 Spec의 §2 영역이다.
- 스펙이나 워크 문서를 수정하지 않는다.
- Decision.md를 수정하지 않는다.
- 구현 코드를 작성하지 않는다.
- 존재하지 않는 디렉토리를 구조에 넣지 않는다.

---

## 완료 체크리스트

- [ ] `doc/templates/Architecture.tpl.md` 읽음
- [ ] `doc/Decision.md` 읽고 기술 선택 확인
- [ ] `doc/Spec.md` 읽고 전체 기능 범위 파악
- [ ] 실제 디렉토리 구조 확인 (`ls`)
- [ ] 기술 스택(§1) 작성 — Decision.md와 일치 확인
- [ ] 전체 엔티티(§2) 작성 — 저장 방식 명시
- [ ] 디렉토리 구조(§3) 작성 — 실제와 일치
- [ ] 시스템 구조도(§4) ASCII 다이어그램 작성
- [ ] 컴포넌트 상세(§5) 모듈별 책임 명시
- [ ] 통신/인터페이스(§6) 참조 스펙 기록
- [ ] 데이터 흐름(§7) 다이어그램 작성
- [ ] 배포/실행 환경(§8) 권한 포함
- [ ] `doc/Architecture.md`에 저장
- [ ] 커밋 & 푸시
