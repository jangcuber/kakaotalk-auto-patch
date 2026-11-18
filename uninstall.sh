#!/bin/bash
set -euo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

label=local.kakaotalk.auto-patch
service="gui/$(id -u)/$label"
if launchctl print "$service" >/dev/null 2>&1; then
    launchctl bootout "$service"
fi
rm -f "$HOME/Library/LaunchAgents/$label.plist"
rm -rf "$HOME/Library/Application Support/KakaoTalk Auto Patch"
printf '%s\n' '자동 패치 작업을 제거했습니다. 현재 카카오톡을 원본으로 복구하려면 README의 안내를 참고하세요.'
