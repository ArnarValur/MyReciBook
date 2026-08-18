#!/usr/bin/env sh
# The ONE way to put MyReciBook on the S21. Plain `flutter build` ships a
# keyless APK where every extraction fails ("kept its secrets") — the keys
# come from dev.env at build time. Burned us twice on 2026-08-18.
set -e
cd "$(dirname "$0")"
flutter build apk --release --dart-define-from-file=dev.env
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb shell monkey -p com.merkurialstudio.myrecibook -c android.intent.category.LAUNCHER 1
