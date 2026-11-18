#!/bin/bash
set -euo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
umask 077

app="${1:-/Applications/KakaoTalk.app}"
[[ -d "$app" && ! -L "$app" ]] || exit 0
here="$(cd "$(dirname "$0")" && pwd)"
binary=Contents/MacOS/KakaoTalk
frameworks=Contents/Frameworks
[[ -x "$app/$binary" && ! -L "$app/$binary" ]] || exit 0
identity="$(codesign -dv "$app" 2>&1)"
printf '%s\n' "$identity" | grep -Fxq 'Identifier=com.kakao.KakaoTalkMac' || exit 0
printf '%s\n' "$identity" | grep -Fxq 'TeamIdentifier=L75WVXX68A' || exit 0

app_running() {
    local processes
    processes="$(ps -ax -o comm=)" || return 0
    printf '%s\n' "$processes" | grep -Fxq "$app/$binary"
}

app_running && exit 0
spctl -a -t exec "$app"
fingerprint() {
    stat -f '%d:%i:%c:%m:%z' "$app" "$app/$binary" "$app/Contents/Info.plist"
    shasum -a 256 "$app/$binary"
}

before="$(fingerprint)"
stage="$(mktemp -d "$(dirname "$app")/.KakaoTalk-before-patch.backup.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
ditto "$app" "$stage"
main="$stage/$binary"
chmod u+w "$main" "$stage/$frameworks"

for lib in NMDKHooker.dylib AdHide.dylib; do
    cp "$here/$lib" "$stage/$frameworks/"
    "$here/optool" install -c load -p "@executable_path/../Frameworks/$lib" -t "$main" >/dev/null
done

codesign -f --deep --preserve-metadata=entitlements -s - "$stage"
codesign --verify --deep --strict "$stage"
cmp "$app/Contents/Info.plist" "$stage/Contents/Info.plist"
diff -q <(codesign -d --entitlements - "$app" 2>/dev/null) \
    <(codesign -d --entitlements - "$stage" 2>/dev/null)
archs="$(lipo -archs "$main")"
for arch in $archs; do
    links="$(otool -arch "$arch" -L "$main")"
    for lib in NMDKHooker.dylib AdHide.dylib; do
        printf '%s\n' "$links" | awk -v path="@executable_path/../Frameworks/$lib" '
            $1 == path { found++ }
            END { exit found != 1 }'
    done
done

[[ "$(fingerprint)" == "$before" ]] || exit 0
app_running && exit 0
trap - EXIT
"$here/swap-bundles" "$app" "$stage"
printf '%s  Applied two patches to %s. Original backup is at %s\n' "$(date '+%F %T')" "$app" "$stage"
