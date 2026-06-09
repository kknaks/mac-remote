# MacRemote — 랜딩 페이지

App Store Connect 제출용 랜딩 페이지. 마케팅 · 지원 · 개인정보 URL을 한 페이지로 처리합니다.

## 파일
- `index.html` — 랜딩 페이지 (단일 파일)
- `assets/AppIcon-128.png` — 앱 아이콘 (로고)
- `assets/01-windows.png` — 창 목록 스크린샷 (히어로)
- `assets/04-mac-qr.png` — Mac 헬퍼 QR 창

## 배포 전 채울 것
`index.html` 맨 아래 `CONFIG` 두 줄만 채우면 모든 다운로드 버튼이 연결됩니다.
비워두면 버튼이 "준비 중" 상태로 표시됩니다.

```js
const CONFIG = {
  APP_STORE_URL: "",   // 출시 후 App Store 앱 링크
  DMG_URL: ""          // MacHelper.dmg 호스팅 주소 (GitHub Releases 권장)
};
```

## App Store Connect URL 매핑
| ASC 필드 | 값 |
|---|---|
| 지원 URL | profile.kknaks.cloud/macremote |
| 마케팅 URL | profile.kknaks.cloud/macremote |
| 개인정보 처리방침 URL | profile.kknaks.cloud/macremote#privacy |

심사 메모 추가 권장:
`The Mac companion app can be downloaded at https://profile.kknaks.cloud/macremote`

## 배포
정적 파일만 있으면 됩니다 (빌드 불필요). 폴더를 그대로 호스팅하세요.
- GitHub Pages / Netlify / Vercel / Cloudflare Pages 등
- 루트에 `index.html`이 오도록 업로드
