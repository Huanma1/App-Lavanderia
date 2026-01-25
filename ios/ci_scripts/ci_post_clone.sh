#!/bin/bash

cd ..

git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:'pwd'/flutter/bin"

flutter precache --ios
flutter pub get

cd ios
pod install
