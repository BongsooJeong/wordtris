# PowerShell 초기화 스크립트 - WordTris 프로젝트용
# 이 스크립트는 프로젝트 환경에서 실행되는 파워쉘 터미널에 로드됩니다.

# 프로젝트 경로 설정
$global:PROJECT_ROOT = "C:\src\code\wordTris"
$global:TOOLS_DIR = Join-Path $PROJECT_ROOT "tools"

# 헬퍼 스크립트 로드
$helperScript = Join-Path $TOOLS_DIR "powershell_helper.ps1"
if (Test-Path $helperScript) {
    . $helperScript
    Write-Host "WordTris 프로젝트 PowerShell 환경이 초기화되었습니다." -ForegroundColor Green
    Write-Host "프로젝트 경로: $PROJECT_ROOT" -ForegroundColor Cyan
} else {
    Write-Host "경고: 헬퍼 스크립트를 찾을 수 없습니다: $helperScript" -ForegroundColor Red
}

# 기본 명령어 단축 함수
function wt-run {
    param (
        [string]$Device = "chrome"
    )
    Push-Location $PROJECT_ROOT
    try {
        flutter run -d $Device
    } finally {
        Pop-Location
    }
}

function wt-export {
    Push-Location $PROJECT_ROOT
    try {
        dart run tools/direct_export.dart
    } finally {
        Pop-Location
    }
}

function wt-cd {
    Set-Location $PROJECT_ROOT
    Write-Host "프로젝트 루트 디렉토리로 이동: $PROJECT_ROOT" -ForegroundColor Green
}

# Cursor를 위한 명령어 래퍼 함수
function cursor-exec {
    param (
        [string]$Command
    )
    
    # && 명령어를 세미콜론으로 변환
    $fixedCommand = $Command -replace '&&', ';'
    Invoke-Expression $fixedCommand
}

# 문법 변환 안내 메시지
Write-Host @"
=== PowerShell 명령어 변환 안내 ===
파워쉘에서 다중 명령어 실행 시:
  - 'cd dir && command' 대신 'cd dir; command' 사용
  - 'command1 && command2' 대신 'command1; command2' 사용

단축 명령어:
  - wt-run: WordTris 앱 실행 (기본: Chrome)
  - wt-export: 한글 빈도 데이터 파일 생성
  - wt-cd: 프로젝트 루트 디렉토리로 이동
=================================
"@ -ForegroundColor Yellow

# Cursor 프롬프트를 위한 항상 변환 함수 설정
$ExecutionContext.InvokeCommand.PreCommandLookupAction = {
    param($CommandName, $CommandLookupEventArgs)
    
    # 터미널에서 실행된 명령이 '&&'를 포함하면 경고 메시지 표시
    if ($CommandName -match '&&') {
        Write-Host "경고: PowerShell에서는 '&&' 대신 ';'를 사용하세요." -ForegroundColor Red
        Write-Host "수정된 명령어: $($CommandName -replace '&&', ';')" -ForegroundColor Yellow
    }
} 