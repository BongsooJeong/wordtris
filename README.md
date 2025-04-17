# 한국어 단어 테트리스 (WordTris)

Flutter로 개발하는 한국어 단어 기반 테트리스 게임입니다.

## 게임 개요
- 일반 테트리스처럼 블록이 떨어지지만, 각 블록에는 한글 글자가 표시됩니다.
- 플레이어는 블록을 회전하고 이동시켜 가로나 세로로 의미 있는 한국어 단어를 완성해야 합니다.
- 단어가 완성되면 해당 줄이 사라지고 점수를 획득합니다.
- 단어의 길이와 난이도에 따라 점수가 차등 부여됩니다.

## 주요 기능
- 한국어 단어 데이터베이스 활용
- 난이도 조절 시스템
- 점수 기록 및 랭킹 시스템
- 다양한 게임 모드 (시간제한, 챌린지 등)

## 기술 스택
- 프레임워크: Flutter
- 언어: Dart
- 상태 관리: Provider
- 데이터 저장: SharedPreferences, SQLite

## 개발 환경 설정
### 필수 요구사항
- Flutter SDK (최신 버전 권장)
- Dart SDK
- 지원 IDE: VS Code, Android Studio, IntelliJ IDEA 또는 Cursor

### 프로젝트 설정
1. 저장소 클론
```
git clone https://github.com/BongsooJeong/wordtris.git
cd wordtris
```

2. 패키지 설치
```
flutter pub get
```

3. 실행
```
flutter run -d chrome
```

## 개발 및 기여
### Git 연동 정보
- 원격 저장소: https://github.com/BongsooJeong/wordtris.git
- 주요 브랜치: master

### 코드 변경 및 제출 방법
1. 코드 변경 후 상태 확인
```
git status
```

2. 변경사항 준비
```
git add .
```

3. 변경사항 커밋
```
git commit -m "변경 내용 설명"
```

4. 원격 저장소에 푸시
```
git push origin master
```

## 개발 로드맵
1. 기본 게임 메커니즘 구현
2. 한국어 단어 데이터베이스 연동
3. UI/UX 디자인 및 구현
4. 게임 모드 및 기능 확장
5. 테스트 및 최적화
6. 출시 및 유지보수 