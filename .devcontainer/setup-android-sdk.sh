#!/usr/bin/env bash
# Ставить мінімальний Android SDK (cmdline-tools + platform-tools + platform 34
# + build-tools 34.0.0), достатній для gradle assembleDebug.
set -e

SDK_ROOT="/opt/android-sdk"
sudo mkdir -p "$SDK_ROOT"
sudo chown -R "$(whoami)" "$SDK_ROOT"

cd /tmp
curl -sSL -o cmdline-tools.zip \
  "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
unzip -q cmdline-tools.zip -d "$SDK_ROOT/cmdline-tools-tmp"
mkdir -p "$SDK_ROOT/cmdline-tools"
mv "$SDK_ROOT/cmdline-tools-tmp/cmdline-tools" "$SDK_ROOT/cmdline-tools/latest"
rm -rf "$SDK_ROOT/cmdline-tools-tmp" cmdline-tools.zip

export ANDROID_HOME="$SDK_ROOT"
export PATH="$PATH:$SDK_ROOT/cmdline-tools/latest/bin:$SDK_ROOT/platform-tools"

yes | sdkmanager --licenses > /dev/null
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

echo "Android SDK готовий. Тепер можна: cd RustSkinAnalyzer && gradle assembleDebug"
