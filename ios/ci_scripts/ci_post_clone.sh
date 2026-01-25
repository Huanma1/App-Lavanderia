#!/bin/bash
cd ..

if [ ! -d "flutter" ]; then
	git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

FLUTTER_PATH=$(pwd)/flutter/bin
export PATH="$PATH:$FLUTTER_PATH"

flutter precache --ios
flutter pub get

cd ios
pod install
