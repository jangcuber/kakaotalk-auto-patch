# macOS 카카오톡 자동 패치

앱스토어에서 설치한 Mac용 카카오톡에 **NoMoreDeletedKaTalk**과 **CocoaKakaoTalkADRemover**를 적용하는 비공식 도구입니다. 처음 설치할 때와 앱스토어에서 카카오톡을 업데이트한 뒤에 패치를 자동으로 적용합니다.

## 알려진 문제

이전 카카오톡 26.9.0 테스트에서 패치된 앱의 **로그인 QR이 비어 있거나 알림으로 연 채팅방이 다른 창 뒤에 남는 증상**이 보고됐습니다. 재서명하면서 권한 목록은 보존하지만 카카오의 개발팀 서명은 달라집니다. 새 빌드에서 QR 로그인과 알림 동작은 확인이 필요합니다. [Apple 앱 그룹 문서](https://developer.apple.com/documentation/xcode/accessing-app-group-containers)

## 설치

1. 앱스토어의 카카오톡이 `/Applications/KakaoTalk.app`에 설치되어 있어야 합니다.
2. Xcode 또는 Xcode Command Line Tools를 준비합니다.
3. 아래 출처에서 `NMDKHooker.dylib`, `CocoaKakaoTalkADRemover/init.m`, Mac의 아키텍처를 지원하는 `optool` 실행 파일을 준비합니다.
4. 카카오톡을 **⌘Q**로 종료하고 저장소 폴더에서 실행합니다.

```bash
./install.sh /path/to/NMDKHooker.dylib /path/to/init.m /path/to/optool
```

기존 자동 패치 작업을 따로 설치했다면 먼저 중지합니다. 예전 `local.kakaotalk.patch-reapply` 작업은 아래와 같이 중지할 수 있습니다. 로그인 시 다시 시작되지 않도록 해당 이름의 plist도 Finder의 `~/Library/LaunchAgents` 폴더에서 제거합니다.

```bash
launchctl bootout "gui/$(id -u)/local.kakaotalk.patch-reapply"
```

## 적용 시점

- 사용자 LaunchAgent가 설치 직후 실행되고, 이후 카톡 앱 변경을 감지하거나 30초 간격으로 확인합니다. 카톡이 실행 중이면 다음에 완전히 종료됐을 때 처리합니다.
- 앱스토어에서 받은 카카오 서명 앱에 패치를 적용합니다. 두 라이브러리 연결과 재서명을 검사한 뒤 검증된 앱을 원래 경로에 교체합니다. 교체 직전 번들은 `/Applications/.KakaoTalk-before-patch.backup.*`에 보관합니다.
- 앱 번들의 `Info.plist`를 보존합니다. Dock 환경설정과 아이콘 리소스는 수정 대상에 포함되지 않습니다.
- 적용 결과는 `~/Library/Application Support/KakaoTalk Auto Patch/reapply.log`에서 확인할 수 있습니다.

## 자동 적용 끄기

```bash
./uninstall.sh
```

자동 작업을 끈 뒤 원본 카톡으로 복구하려면 앱스토어에서 카카오톡을 다시 설치하거나 응용 프로그램 폴더에 보관된 백업을 사용하세요.

## 출처

- BawAppie의 NoMoreDeletedKaTalk. [공식 페이지](https://nmdk.repo.co.kr/)
- Jinwoo Kim(pookjw)의 CocoaKakaoTalkADRemover. [원본 저장소](https://github.com/pookjw/CocoaKakaoTalkADRemover)
- Alex Zielenski의 optool. [원본 저장소 및 BSD 라이선스](https://github.com/alexzielenski/optool#license)

저장소에는 자동 적용 도구의 소스가 들어 있습니다. 설치 스크립트는 사용자가 지정한 로컬 파일을 사용합니다.
