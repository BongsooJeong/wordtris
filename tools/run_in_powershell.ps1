# 파워쉘 스크립트: 빈도 분석 결과를 파일로 정리
# 사용법: .\run_in_powershell.ps1

# 작업 디렉토리를 프로젝트 루트로 변경
cd ..;

# 빈도 분석 실행
dart run tools/korean_char_frequency.dart;

# 결과 데이터를 100개 단위로 파일로 정리
dart run tools/export_frequency_data.dart;

# 완료 메시지
Write-Host "모든 처리가 완료되었습니다." -ForegroundColor Green; 