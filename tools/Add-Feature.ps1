<#
.SYNOPSIS
  툴 상세 페이지(<tool>.html)에 기능 카드(제목 + 설명 + GIF/이미지)를 추가한다.
.EXAMPLE
  tools\Add-Feature.ps1 -Tool MultiCapture -Title "AniGif" -Description "Record any part of your screen as an animated GIF." -Image C:\temp\anigif.gif
.NOTES
  필수 입력(-Tool -Title -Description -Image)이 없거나 규칙을 어기면 아무것도 바꾸지 않고 중단한다.
  규칙: 제목/설명은 영문(한글 불가), 이미지 gif/png/jpg/webp, 최대 10MB, 가로 최대 760px.
#>
param(
  [string]$Tool,
  [string]$Title,
  [string]$Description,
  [string]$Image,
  [string]$Section,   # 섹션 마커 이름. 생략하면 기본 마커(features:end), 지정하면 <!-- features:end:이름 -->
  [string]$Before,    # 이 제목의 카드 바로 앞에 삽입(같은 섹션 안). 생략하면 섹션 맨 끝
  [switch]$Replace,   # 같은 이름의 이미지 파일을 덮어쓴다
  [switch]$DryRun     # 검증까지만 하고 파일은 건드리지 않는다
)

$ErrorActionPreference = 'Stop'
$MaxBytes = 10MB
$MaxWidth = 760
$Root     = Split-Path -Parent $PSScriptRoot
$Marker   = if ($Section) { "<!-- features:end:$Section -->" } else { '<!-- features:end -->' }

function Fail([string]$msg) { Write-Host "[거부] $msg" -ForegroundColor Red; exit 1 }

# --- 1. 필수 입력 ---
$missing = @()
if (-not $Tool)        { $missing += '-Tool (툴 이름, 예: MultiCapture)' }
if (-not $Title)       { $missing += '-Title (기능명)' }
if (-not $Description) { $missing += '-Description (기능 설명, 영문 1~2문장)' }
if (-not $Image)       { $missing += '-Image (GIF/이미지 파일 경로)' }
if ($missing) { Fail ("필수 항목 누락:`n  " + ($missing -join "`n  ")) }

# --- 2. 툴/페이지 ---
$cfg = Get-Content (Join-Path $PSScriptRoot 'tools.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $cfg.PSObject.Properties[$Tool]) { Fail "tools.json에 없는 툴: $Tool" }
$slugTool = $Tool.ToLower()
$page = Join-Path $Root "$slugTool.html"
if (-not (Test-Path $page)) { Fail "페이지 없음: $slugTool.html" }
$html = [IO.File]::ReadAllText($page, [Text.Encoding]::UTF8)
if ($html -notmatch [regex]::Escape($Marker)) { Fail "$slugTool.html 에 마커($Marker)가 없다. .features 블록 끝에 추가할 것." }

# --- 3. 텍스트 규칙 ---
$Title = $Title.Trim(); $Description = $Description.Trim()
if ($Title.Length -gt 40)        { Fail "기능명은 40자 이하 (현재 $($Title.Length))" }
if ($Description.Length -lt 10)  { Fail '설명이 너무 짧다 (10자 이상, 영문 1~2문장)' }
if ($Description.Length -gt 200) { Fail "설명은 200자 이하 (현재 $($Description.Length))" }
if (($Title + $Description) -match '[\uAC00-\uD7A3\u3131-\u318E]') { Fail '사이트 본문은 영문. 제목/설명에 한글 불가' }
$encTitle = [Net.WebUtility]::HtmlEncode($Title)
if ($html -match ('<h3>' + [regex]::Escape($encTitle) + '</h3>')) { Fail "이미 같은 제목의 기능 카드가 있다: $Title" }

# --- 4. 이미지 규칙 ---
if (-not (Test-Path $Image -PathType Leaf)) { Fail "이미지 파일 없음: $Image" }
$file = Get-Item $Image
$ext  = $file.Extension.ToLower()
if ($ext -notin '.gif', '.png', '.jpg', '.jpeg', '.webp') { Fail "지원하지 않는 확장자: $ext (gif/png/jpg/webp)" }
if ($file.Length -gt $MaxBytes) { Fail ("용량 초과: {0:N1}MB > {1}MB. 줄여서 다시 시도" -f ($file.Length / 1MB), ($MaxBytes / 1MB)) }

$b = [IO.File]::ReadAllBytes($file.FullName)
$w = 0; $h = 0
if ($ext -eq '.gif' -and $b.Length -ge 10) {
  $w = $b[6] + 256 * $b[7]; $h = $b[8] + 256 * $b[9]
} elseif ($ext -eq '.png' -and $b.Length -ge 24) {
  $w = ([int]$b[16] * 16777216) + ([int]$b[17] * 65536) + ([int]$b[18] * 256) + $b[19]
  $h = ([int]$b[20] * 16777216) + ([int]$b[21] * 65536) + ([int]$b[22] * 256) + $b[23]
}
if ($w -gt $MaxWidth) { Fail "가로 ${w}px > ${MaxWidth}px. 리사이즈 후 다시 시도" }

$slug = ($Title.ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
if (-not $slug) { Fail '기능명에서 파일명을 만들 수 없다 (영문/숫자 포함 필요)' }
$destDir  = Join-Path $Root "images\$slugTool"
$destFile = Join-Path $destDir ($slug + ($ext -replace '\.jpeg', '.jpg'))
if ((Test-Path $destFile) -and -not $Replace) { Fail "이미 존재: images/$slugTool/$(Split-Path $destFile -Leaf) (덮어쓰려면 -Replace)" }

# --- 5. 카드 생성 ---
$imgW = 380
$imgH = 225   # 760:450 틀 고정. 비율이 다른 이미지는 CSS(object-fit: contain)가 레터박스 처리
$rel  = "images/$slugTool/" + (Split-Path $destFile -Leaf)
$encDesc = [Net.WebUtility]::HtmlEncode($Description)
$card = @"
      <div class="feature">
        <div><h3>$encTitle</h3><p>$encDesc</p></div>
        <img src="$rel" alt="$encTitle" width="$imgW" height="$imgH" loading="lazy">
      </div>
"@

# --- 5.5 삽입 위치 (DryRun에서도 검증) ---
$idx = $html.IndexOf($Marker)
if ($Before) {
  $h3 = '<h3>' + [Net.WebUtility]::HtmlEncode($Before.Trim()) + '</h3>'
  $at = $html.IndexOf($h3)
  if ($at -lt 0) { Fail "-Before 카드를 찾을 수 없다: $Before" }
  $next = $html.IndexOf('<!-- features:end', $at)
  if ($next -ne $idx) { Fail "-Before 카드가 지정한 섹션($Marker) 안에 있지 않다: $Before" }
  $idx = $html.LastIndexOf('<div class="feature">', $at)   # 카드 여는 태그 앞에 삽입
  if ($idx -lt 0) { Fail "-Before 카드의 시작 태그를 찾을 수 없다: $Before" }
}
$where = if ($Before) { "'$Before' 카드 앞" } else { '섹션 맨 끝' }

Write-Host "툴: $Tool / 제목: $Title / 이미지: $rel (${w}x${h}, $([math]::Round($file.Length/1KB))KB)"
if ($DryRun) { Write-Host '[DryRun] 검증 통과. 변경 없음.' -ForegroundColor Yellow; exit 0 }

# --- 6. 적용 ---
New-Item -ItemType Directory -Force $destDir | Out-Null
Copy-Item $file.FullName $destFile -Force
$lineStart = $html.LastIndexOf("`n", $idx) + 1
$html = $html.Insert($lineStart, $card + "`n")
[IO.File]::WriteAllText($page, $html, (New-Object Text.UTF8Encoding($false)))
Write-Host "추가 완료: $slugTool.html ($where), $rel" -ForegroundColor Green
