#!/bin/bash
set -euo pipefail

cd "$CI_PRIMARY_REPOSITORY_PATH"

if ! command -v flutter >/dev/null 2>&1; then
    echo "Flutter is not installed. Installing Flutter SDK..."
    git clone https://github.com/flutter/flutter.git --depth 1 -b 3.38.5 "$HOME/flutter"
    export PATH="$PATH:$HOME/flutter/bin"
fi

flutter --version
flutter precache --ios
flutter pub get

cd ios
pod install --deployment
