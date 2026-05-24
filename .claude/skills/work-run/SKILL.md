# /work-run — 워크플랜 기반 TDD 구현

## 읽어야 할 파일 (이것만 읽는다)

1. `doc/work/Work-NN-slug.md` — 대상 워크플랜 (태스크 목록, 검증 방법)
2. `doc/spec/Spec-NN-slug.md` — 워크가 참조하는 스펙 (**워크 헤더의 "관련 스펙"에 명시된 것만**)
3. `doc/Work.md` — 인덱스 (상태 갱신용)

## 갱신해야 할 파일

- `doc/work/Work-NN-slug.md` — 태스크 상태 + 커밋 해시
- `doc/Work.md` — 워크 상태 + 스펙 커버리지

---

## TDD 사이클

모든 태스크는 아래 사이클을 따른다:

```
1. RED    — 스펙 기반으로 테스트 작성 → 실행 → 실패 확인
   ▼
2. GREEN  — 테스트를 통과하는 최소 구현
   ▼
3. REFACTOR — 중복 제거, 구조 개선 (테스트 여전히 통과)
   ▼
4. COMMIT — 커밋 생성 → 해시를 Work-detail 태스크 테이블에 기록
   ▼
5. NEXT   — 다음 태스크로 이동
```

### 테스트 작성 규칙

- 테스트 파일은 소스와 같은 모듈/패키지 안에 `Tests/` 디렉토리를 둔다.
- 테스트 이름은 `test_<행위>_<조건>_<기대결과>` 형식.
- 스펙의 계약(§3)과 인수 조건(§10)을 기준으로 테스트 케이스를 도출한다.
- 엣지 케이스(§9)도 테스트한다.
- 테스트가 불가능한 항목(UI, 권한, 하드웨어 의존)은 건너뛰되 Work-detail §5 검증 방법에 수동 검증 절차를 기록한다.

---

## 작업 규칙

1. 워크의 태스크 순서대로 진행한다. 순서를 건너뛰지 않는다.
2. 한 태스크가 끝나면 반드시 커밋하고, 커밋 해시를 Work-detail에 기록한다.
3. 태스크가 모두 끝나면 Work-detail 상태를 Done으로 변경한다.
4. Work 인덱스의 해당 행 상태를 갱신한다.
5. 스펙 체크리스트(§2)를 하나씩 체크하며 진행한다 — 모든 항목이 체크되면 인덱스 커버리지를 Full로 변경.
6. 구현 중 스펙과 충돌하는 부분을 발견하면 구현을 멈추고 사용자에게 `/doc-spec` 갱신을 안내한다.

## 예제

### TDD 사이클 예시

```
# 1. RED — 테스트 먼저
func test_listWindows_layerZeroOnly_returnsNormalWindows() {
    let windows = WindowManager.listWindows()
    for w in windows {
        XCTAssertEqual(w.layer, 0)
    }
}
# 실행 → ❌ 컴파일 에러 (WindowManager 미존재)

# 2. GREEN — 최소 구현
struct WindowInfo { ... }
class WindowManager {
    static func listWindows() -> [WindowInfo] { ... }
}
# 실행 → ✅ 통과

# 3. REFACTOR — 정리
# (필요 시)

# 4. COMMIT
git commit -m "feat: add WindowManager.listWindows with layer filtering"
# 해시: a1b2c3d
```

### Work-detail 태스크 갱신 예시

```markdown
| 1 | WindowInfo 모델 정의 | [x] | a1b2c3d | |
| 2 | CGWindowList 호출 및 필터링 | [x] | d4e5f6a | |
| 3 | 권한 상태 체크 로직 | [ ] | | 다음 작업 |
```

### Work 인덱스 갱신 예시

```markdown
## 워크 현황
| Work-01 | CLI 프로토타입 | @me | Done | 2026-05-24 | 2026-05-25 | — | Spec-01 |

## 스펙 커버리지
| Spec-01 | Work-01 | Full | |
```

---

## 해야 하는 것 (DO)

- 코드 작성 전에 반드시 테스트를 먼저 작성한다 (RED 단계).
- 테스트를 실행해서 실패를 확인한 후 구현에 들어간다.
- 스펙의 계약(JSON 형식, 필드명, 타입)을 정확히 따른다.
- 스펙의 에러 처리(§5)에 명시된 복구 전략을 구현한다.
- 태스크마다 커밋하고 해시를 기록한다 — 커밋 없는 태스크 완료는 없다.
- 구현 완료 후 Work-detail §5 검증 방법의 절차를 실행하고 결과를 기록한다.
- 검증까지 끝나면 인덱스를 갱신하고 커밋 & 푸시한다.

## 하지 말아야 할 것 (DON'T)

- 테스트 없이 구현하지 않는다.
- 테스트를 통과시키기 위해 테스트를 수정하지 않는다 — 구현을 수정한다.
- 스펙에 없는 기능을 추가하지 않는다.
- 스펙과 충돌하는 구현을 스펙 수정 없이 밀어넣지 않는다.
- Decision.md, Spec 문서를 수정하지 않는다.
- 한 커밋에 여러 태스크를 섞지 않는다 — 1 태스크 = 1 커밋.
- 테스트 불가능한 항목을 테스트된 것처럼 표시하지 않는다 — 수동 검증으로 분류.

---

## 완료 체크리스트

- [ ] 대상 Work-detail 읽음
- [ ] 참조 Spec 읽음
- [ ] 태스크별 TDD 사이클 수행:
  - [ ] RED: 테스트 작성 → 실패 확인
  - [ ] GREEN: 최소 구현 → 통과 확인
  - [ ] REFACTOR: 정리
  - [ ] COMMIT: 커밋 → 해시 기록
- [ ] Work-detail §2 스펙 체크리스트 모두 체크
- [ ] Work-detail §3 태스크 모두 체크 + 커밋 해시 기록
- [ ] Work-detail §5 검증 방법 실행 → 결과 기록
- [ ] Work-detail 상태를 Done으로 변경
- [ ] `doc/Work.md` 인덱스 상태 갱신
- [ ] `doc/Work.md` 스펙 커버리지 갱신
- [ ] 최종 커밋 & 푸시
