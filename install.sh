#!/bin/bash
set -euo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
umask 077

if [[ $# != 3 ]]; then
    printf '사용법: %s <NMDKHooker.dylib> <CocoaKakaoTalkADRemover/init.m> <optool>\n' "$0" >&2
    exit 2
fi

root="$(cd "$(dirname "$0")" && pwd)"
nmdk="$1"
ad_source="$2"
optool="$3"
binary=/Applications/KakaoTalk.app/Contents/MacOS/KakaoTalk
label=local.kakaotalk.auto-patch
domain="gui/$(id -u)"
support="$HOME/Library/Application Support/KakaoTalk Auto Patch"
agents="$HOME/Library/LaunchAgents"
plist="$agents/$label.plist"

for input in "$nmdk" "$ad_source" "$optool" "$binary"; do
    if [[ ! -f "$input" ]]; then
        printf '필요한 파일이 없습니다. %s\n' "$input" >&2
        exit 1
    fi
done
if [[ -e "$support" || -L "$support" || -e "$plist" || -L "$plist" ]] ||
    launchctl print "$domain/$label" >/dev/null 2>&1; then
    printf '%s\n' '이미 설치되어 있습니다. 먼저 uninstall.sh를 실행해 주세요.' >&2
    exit 1
fi
if launchctl print "$domain/local.kakaotalk.patch-reapply" >/dev/null 2>&1; then
    printf '%s\n' '이전 자동 패치 작업(local.kakaotalk.patch-reapply)을 먼저 중지해 주세요.' >&2
    exit 1
fi

read -r -a architectures <<< "$(lipo -archs "$binary")"
lipo "$optool" -verify_arch "$(uname -m)"
arch_flags=()
for arch in "${architectures[@]}"; do
    lipo "$nmdk" -verify_arch "$arch"
    arch_flags+=(-arch "$arch")
done

mkdir -p "$agents" "$(dirname "$support")"
stage="$(mktemp -d "$(dirname "$support")/.kakao-patch-install.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
mkdir "$stage/files"
xcrun clang -Wall -Wextra "$root/src/swap-bundles.c" -o "$stage/files/swap-bundles"
xcrun clang -fobjc-arc -dynamiclib "${arch_flags[@]}" -framework AppKit \
    -o "$stage/files/AdHide.dylib" -- "$ad_source"
cp -- "$nmdk" "$stage/files/NMDKHooker.dylib"
cp -- "$optool" "$stage/files/optool"
chmod u+x "$stage/files/optool"
cp "$root/src/patch-after-update.sh" "$stage/files/"

plutil -create xml1 "$stage/agent.plist"
plutil -insert Label -string "$label" "$stage/agent.plist"
plutil -insert ProgramArguments -array "$stage/agent.plist"
plutil -insert ProgramArguments.0 -string /bin/bash "$stage/agent.plist"
plutil -insert ProgramArguments.1 -string "$support/patch-after-update.sh" "$stage/agent.plist"
plutil -insert RunAtLoad -bool YES "$stage/agent.plist"
plutil -insert StartInterval -integer 30 "$stage/agent.plist"
plutil -insert WatchPaths -array "$stage/agent.plist"
plutil -insert WatchPaths.0 -string /Applications/KakaoTalk.app/Contents/Info.plist "$stage/agent.plist"
plutil -insert StandardOutPath -string "$support/reapply.log" "$stage/agent.plist"
plutil -insert StandardErrorPath -string "$support/reapply.log" "$stage/agent.plist"
plutil -lint "$stage/agent.plist"

mkdir -m 700 "$support"
if ! ditto "$stage/files" "$support" || ! install -m 600 "$stage/agent.plist" "$plist" || ! launchctl bootstrap "$domain" "$plist"; then
    rm -f "$plist"
    rm -rf "$support"
    exit 1
fi
printf '설치 완료. 카카오톡이 종료되면 자동으로 패치를 적용합니다.\n로그: %s\n' "$support/reapply.log"
