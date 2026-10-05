# ReleaseUtils (프리웨어 배포 저장소 · 사이트)

## 프로젝트
`dev245g-hash/dev245g-hash.github.io` — 개인 개발 유틸(MultiCapture, MultiView, 추후 ~5개)의 **릴리즈 + 소개 페이지** 저장소.
소스 코드는 각 툴 저장소에 있고, 여기에는 **배포물(Releases) · 소개 문서 · 이미지 · 공통 배포 스크립트**만 둔다.
로컬 위치: `D:\Claude\ReleaseUtils` (git clone). 편집은 로컬에서 하고 git으로 푸시한다.

## 구조

| 경로 | 역할 |
|------|------|
| `index.html` | 사이트 홈. 툴 카드(설명 + 데모 이미지 + Download/Details) + 라이선스 + 후원 |
| `<tool>.html` (소문자) | 툴 상세 페이지: 히어로 + Download 버튼 + 투어 이미지 + 기능 카드 + 기능 목록 + **Version List(`#versions`, 최하단)** |
| `assets/site.css` | 공통 스타일. 다크 기반, `prefers-color-scheme: light` 및 수동 토글(`data-theme`) 대응 |
| `assets/site.js` | 테마 토글 + Download 버튼 자동 조회(아래) |
| `.nojekyll` | Jekyll 처리 끔(정적 HTML 그대로 서빙) |
| `README.md`, `<Tool>.md` | 저장소 화면용 **축약본**. 사이트 링크 + Releases 링크만 둔다(내용 복제 금지) |
| `images/<tool>/` | 문서에서 쓰는 이미지. **repo에 커밋하고 `raw.githubusercontent.com` 경로로 참조** |
| `tools/Publish-Release.ps1` | 공통 배포 스크립트 (`-Tool`, `-Version`) |
| `tools/Add-Feature.ps1` | 기능 카드 추가 스크립트 ("피쳐" 명령, 아래) |
| `tools/tools.json` | 툴별 설정(소스 경로 · csproj · exe · 버전 문자열 위치) |

## 규칙
- 이미지는 repo의 `images/<tool>/`(하위 폴더 없이 평평하게)에 커밋한다. 사이트 페이지(`*.html`)는 **상대경로**(`images/<tool>/x.gif`), 저장소 화면용 `README.md`/`<Tool>.md`만 `raw.githubusercontent.com` 경로를 쓴다. `user-attachments`(웹 드래그 첨부)는 API로 만들 수 없고 repo 이력에 없어 신규 문서에는 쓰지 않는다. (기존 것은 유지)
- 이미지 용량: git 이력은 삭제되지 않으므로 **확정된 최종본만 커밋**한다. 기능 카드 이미지는 10MB 이하, 가로 760px 이하. GIF를 영상으로 재변환하지 않는다(화질 손해). 영상은 원본 녹화본에서 직접 변환한 경우만 `<video autoplay loop muted playsinline>`으로 쓴다.
- 기능 카드: 기능마다 `<div class="feature">` 1개 = `<div><h3>제목</h3><p>설명</p></div>` + `<img width="380" height="225">`(이미지 틀은 760:450 고정, 비율이 다르면 CSS `object-fit: contain`으로 레터박스). 레이아웃은 CSS grid(`site.css`)가 맡으므로 표·인라인 너비 지정 금지. 모바일(<=760px)은 세로로 쌓인다.
- Version List: `<tool>.html` 최하단 `<table class="versions">`. 행 형식 = `<tr><td><strong>Ver.YYYY.MM.DD</strong>[<span class="badge">Latest</span>]</td><td>변경 내용(영문, 항목 사이 <br>)</td><td><a href="…/releases#release-<Tool>/Ver.YYYY.MM.DD">Download</a></td></tr>`. 새 행은 `<tbody>` 맨 위, `Latest` 배지(`<span class="badge">`)는 새 버전 행으로 옮긴다. (8~9번 자동화 후 데이터 파일로 이동 예정)
- Download 버튼: `<a class="btn" data-download="<Tool>" href="…/releases">Download <small></small></a>`. `site.js`가 GitHub API(`/releases?per_page=50`)에서 태그가 `<Tool>/`로 시작하는 최신 공개 릴리즈의 `.zip` 에셋 URL과 버전을 채운다(10분 sessionStorage 캐시). 실패하면 `href`(Releases 페이지)가 폴백. 툴마다 태그가 달라 `releases/latest`는 쓰지 않는다. zip 에셋이 하나만 있다는 전제.
- 사이트 이미지: `user-attachments`는 기존 것만 유지, 신규는 `images/<tool>/` + raw URL.
- 새 툴 페이지 헤더 nav에는 모든 페이지에 링크를 추가한다(현재 페이지에 `aria-current="page"`).
- 릴리즈 본문은 영문 먼저, 한글 나중.
- 툴을 추가할 때: ①`tools/tools.json`에 항목 추가 ②`<tool>.html` 생성(기존 페이지 복제) + 짧은 `<Tool>.md` ③`index.html` 카드와 `README.md` 표, 모든 페이지 nav에 추가 ④해당 툴 `CLAUDE.md`의 배포 Flow가 이 저장소의 공통 스크립트를 가리키게 한다.

## "피쳐" 명령 (기능 카드 추가)
"피쳐" 라고 지시하면 `tools\Add-Feature.ps1`로 `<tool>.html`에 기능 카드를 추가한다. 아래 4가지가 **모두** 있어야 하며, 하나라도 없으면 추가하지 말고 부족한 항목을 되물어 거부한다.
1. 대상 툴 이름 (`tools.json`에 있는 이름). **어느 툴에 추가하는지 사용자가 명시해야 한다.** 대화 맥락·IDE에 열린 파일·직전 작업 툴로 추측하지 않고, 없으면 되묻는다.
2. 기능명 (영문, 40자 이하)
3. 설명 (영문 1~2문장, 10~200자)
4. 이미지 파일 경로 (gif/png/jpg/webp, 10MB 이하, 가로 760px 이하, 760x450 권장)
- 사용자가 한글로 제목/설명을 주면 영문으로 번역안을 제시해 확인받은 뒤 진행한다(사이트 본문은 영문).
- 실행: `tools\Add-Feature.ps1 -Tool <Tool> -Title "<기능명>" -Description "<설명>" -Image <경로>` → 먼저 `-DryRun`으로 검증 후 실제 실행.
- 동작: 이미지를 `images/<tool>/<기능명-슬러그>.<ext>`로 복사하고, `.features` 끝의 `<!-- features:end -->` 마커 앞에 카드(`width=380 height=225`, `loading="lazy"`)를 삽입한다. 같은 제목/파일명이 있으면 거부(파일은 `-Replace`로 덮어쓰기).
- 상세 페이지 섹션 형식: 헤더는 `<header class="sec-head"><span class="ico">이모지</span><div><h2>제목</h2><p>한 줄 설명</p></div></header>`, 목록은 `<ul class="points">` + `<li><strong>항목명</strong>간결한 설명</li>`(전폭이 필요하면 `class="wide"`). 순서: 히어로 → 툴바 이미지 → Screen Capture 섹션(헤더 → GIF 기능 카드 `.features` → 요약 목록) → 나머지 그룹 → Version List. 같은 내용을 카드·목록에 중복해서 쓰지 않는다.
- 섹션별 카드: 기본은 `<!-- features:end -->`(Screen Capture 섹션). 다른 섹션에 넣으려면 그 섹션의 `.features` 끝에 `<!-- features:end:<이름> -->` 마커를 두고 `-Section <이름>`으로 지정한다(예: Eyedropper & Palette → `eyedropper`). 어느 섹션인지도 사용자가 명시해야 하며 없으면 기본 섹션으로 가정하지 말고 되묻는다.
- "피쳐"는 **추가 전용**이다. 기존 카드(임시 이미지 교체 등)의 수정·삭제·순서 변경은 별도 지시로 `<tool>.html`을 직접 편집한다. 마커 주석은 지우지 않는다. 새 툴 페이지를 만들 때도 `.features` 끝에 마커를 넣는다.
- 규칙 위반 시 스크립트가 아무것도 바꾸지 않고 중단하므로, 우회하지 않고 사용자에게 수정을 요청한다. "깃" 지시 전에는 커밋하지 않는다.

## 배포 (공통 스크립트)
```powershell
tools\Publish-Release.ps1 -Tool MultiView -Version 2026.01.01
```
- 하는 일: 버전 문자열 검사 → Release 빌드 → exe 1개만 zip → draft 릴리즈(태그 `<Tool>/Ver.<날짜>`) 생성 → zip 업로드 → 편집 화면 열기.
- 옵션: `-SkipBuild` `-DryRun`(API 호출 없이 검증까지만) `-NoOpen` `-Publish`(바로 공개).
- 본문은 **소스 저장소**의 `promotion\releases\<날짜>.md` (툴별 CLAUDE.md의 배포 Flow 1단계가 작성·검토).
- 토큰: `$env:GH_TOKEN` 우선, 없으면 `git credential fill`. **값 출력·저장 금지.**
- 창 제목 버전(`*.Designer.cs`)이 `-Version`과 다르면 중단한다. 디자이너 영역이라 Claude가 고치지 않고 사용자에게 요청한다.

## 설계 메모 / 미결
- 각 툴 저장소의 배포 Flow는 이 공통 스크립트를 쓰도록 교체됨(툴 쪽 `tools\Publish-Release.ps1`은 제거). 첫 실배포 때 draft 생성까지 정상인지 확인할 것.
- 이미지 자동화: 이미지를 `images/<tool>/<날짜>/`에 커밋하고 raw URL을 본문에 넣으면 draft 단계에서 이미지까지 자동화 가능 → 사람은 Publish만 누르면 된다. 미구현.
- 버전 리스트 갱신 대상: `<tool>.html`의 Version List 표(수동). 데이터 분리·스크립트 자동화는 미구현(8~9번).
- 저장소 이름은 `dev245g-hash.github.io`로 변경 완료(사이트 루트 https://dev245g-hash.github.io/ , Pages: main `/`, legacy Jekyll). 옛 `ReleaseUtils` 주소는 GitHub 리다이렉트로 살아 있으므로 외부 게시글(promotion 문서 등)의 옛 링크는 그대로 둬도 동작한다. 단 같은 이름으로 새 저장소를 만들면 리다이렉트가 끊긴다.
- 사이트는 직접 만든 정적 HTML(`index.html` + `.nojekyll`, 다크 기반)로 전환 완료. 푸시 후 Pages 반영(수 분)·실제 URL에서 Download 버튼 동작을 확인할 것. 기능 카드 3개(Scroll/Pin/AniGif)의 이미지는 아직 같은 임시 이미지.

## 버전 관리
- "깃" 지시가 있을 때만 commit/push (전역 규칙). 브랜치 `main`.

## 주요 사이트
- 후원: https://ko-fi.com/dev245
