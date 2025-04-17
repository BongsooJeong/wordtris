# Cursor 파워쉘 프로필
# 이 파일은 커서 IDE에서 PowerShell 터미널이 시작될 때 자동으로 로드됩니다.

# 프로젝트 경로 설정
$projectPath = "C:\src\code\wordTris"

# 명령어 래핑 함수: 파워쉘에서 명령어 분리자를 & 대신 ; 로 자동 변환
function Invoke-ConvertedCommand {
    param(
        [string]$Command
    )
    
    $convertedCommand = $Command -replace "&&", ";"
    Write-Host "실행 중: $convertedCommand" -ForegroundColor Cyan
    Invoke-Expression $convertedCommand
}

# 특수 함수: 폴더 이동과 명령 실행 통합
function Set-LocationAndExecute {
    param(
        [string]$Path,
        [string]$Command
    )
    
    try {
        Push-Location $Path
        $convertedCommand = $Command -replace "&&", ";"
        Write-Host "위치: $Path" -ForegroundColor Yellow
        Write-Host "실행 중: $convertedCommand" -ForegroundColor Cyan
        Invoke-Expression $convertedCommand
    }
    finally {
        Pop-Location
    }
}

# 명령어 전처리 이벤트 핸들러
$ExecutionContext.InvokeCommand.PreCommandLookupAction = {
    param($CommandName, $CommandLookupEventArgs)
    
    if ($CommandName -match "cd\s+([^&]+)\s*&&\s*(.+)") {
        $directory = $Matches[1].Trim()
        $command = $Matches[2].Trim()
        
        Write-Host "PowerShell 명령 변환 감지: cd $directory && $command" -ForegroundColor Yellow
        Write-Host "변환된 실행: cd $directory; $command" -ForegroundColor Green
        
        # 명령어 검색 결과를 Set-LocationAndExecute로 수정
        $CommandLookupEventArgs.CommandScriptBlock = {
            Set-LocationAndExecute -Path $directory -Command $command 
        }.GetNewClosure()
    }
    elseif ($CommandName -match "(.+)\s*&&\s*(.+)") {
        $command1 = $Matches[1].Trim()
        $command2 = $Matches[2].Trim()
        
        # 복합 명령 처리
        $CommandLookupEventArgs.CommandScriptBlock = {
            Write-Host "PowerShell 다중 명령 변환:" -ForegroundColor Yellow
            Write-Host "  원본: $command1 && $command2" -ForegroundColor Yellow
            Write-Host "  변환: $command1; $command2" -ForegroundColor Green
            Invoke-Expression "$command1; $command2"
        }.GetNewClosure()
    }
}

# 프로젝트 관련 작업 함수
function Run-WordTris {
    param(
        [string]$Device = "chrome"
    )
    
    Set-LocationAndExecute -Path $projectPath -Command "flutter run -d $Device"
}

function Export-KoreanCharacters {
    Set-LocationAndExecute -Path $projectPath -Command "dart run tools/direct_export.dart"
}

# 도움말 출력
Write-Host "=== 커서 IDE 파워쉘 환경 로드됨 ===" -ForegroundColor Magenta
Write-Host "주요 명령어:" -ForegroundColor Cyan 
Write-Host "- Run-WordTris [-Device chrome|windows|...]: 앱 실행" -ForegroundColor White
Write-Host "- Export-KoreanCharacters: 한글 빈도 파일 생성" -ForegroundColor White
Write-Host "- cd directory; command    # PowerShell에서 다중 명령 실행" -ForegroundColor White
Write-Host "==============================="-ForegroundColor Magenta 