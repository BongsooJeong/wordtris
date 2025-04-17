# PowerShell 명령어 실행 헬퍼 스크립트
# 이 파일은 프로젝트에서 실행되는 명령어가 파워쉘 문법에 맞게 변환되도록 도와줍니다

# 함수: 쉘 명령어 변환
function Convert-ShellCommand {
    param (
        [string]$Command
    )
    
    # 명령어에서 && 연산자를 ; 로 변환
    $convertedCommand = $Command -replace '&&', ';'
    
    # cd 명령 패턴 변환
    $convertedCommand = $convertedCommand -replace 'cd (.*?) && (.*)', 'cd $1; $2'
    
    return $convertedCommand
}

# 함수: 명령어 실행
function Invoke-SafeCommand {
    param (
        [string]$Command
    )
    
    $convertedCommand = Convert-ShellCommand -Command $Command
    Write-Host "실행 명령어: $convertedCommand" -ForegroundColor Cyan
    
    try {
        Invoke-Expression $convertedCommand
        return $true
    }
    catch {
        Write-Host "명령어 실행 오류: $_" -ForegroundColor Red
        return $false
    }
}

# 함수: 다트/플러터 명령어 실행
function Invoke-DartCommand {
    param (
        [string]$Command,
        [string]$WorkingDirectory = "."
    )
    
    $originalLocation = Get-Location
    
    try {
        if ($WorkingDirectory -ne ".") {
            Set-Location $WorkingDirectory
        }
        
        if ($Command -match "^flutter ") {
            Write-Host "Flutter 명령어 실행 중..." -ForegroundColor Green
        }
        elseif ($Command -match "^dart ") {
            Write-Host "Dart 명령어 실행 중..." -ForegroundColor Blue
        }
        
        Invoke-SafeCommand -Command $Command
    }
    finally {
        if ($WorkingDirectory -ne ".") {
            Set-Location $originalLocation
        }
    }
}

# 공통 명령어 단축키 함수
function Run-Flutter {
    param (
        [string]$Device = "chrome"
    )
    
    Write-Host "Flutter 앱 실행 ($Device)..." -ForegroundColor Green
    Invoke-DartCommand -Command "flutter run -d $Device" -WorkingDirectory "C:\src\code\wordTris"
}

function Run-DirectExport {
    Write-Host "한글 글자 빈도 데이터 파일 생성..." -ForegroundColor Yellow
    Invoke-DartCommand -Command "dart run tools/direct_export.dart" -WorkingDirectory "C:\src\code\wordTris"
}

# 사용법 표시
Write-Host "== PowerShell 명령어 헬퍼 로드됨 ==" -ForegroundColor Magenta
Write-Host "명령어 예시:" -ForegroundColor Cyan
Write-Host "  Run-Flutter              # 기본 브라우저(chrome)에서 앱 실행" -ForegroundColor White
Write-Host "  Run-Flutter -Device 'windows' # Windows에서 앱 실행" -ForegroundColor White
Write-Host "  Run-DirectExport         # 한글 글자 빈도 데이터 파일 생성" -ForegroundColor White
Write-Host "  Invoke-SafeCommand -Command 'cd tools; dart run direct_export.dart'" -ForegroundColor White
Write-Host "=============================================" -ForegroundColor Magenta

# 모듈 내보내기
Export-ModuleMember -Function Invoke-SafeCommand, Invoke-DartCommand, Run-Flutter, Run-DirectExport, Convert-ShellCommand 