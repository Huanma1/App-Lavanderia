#!/usr/bin/env bash

# Salir si hay un error
set -e

# 1. Instalar Flutter (si no usas una versión específica, puedes clonar el repo)
git clone https://github.com/flutter/flutter.git -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# 2. Pre-descargar artefactos
flutter precache --ios

# 3. Obtener dependencias
flutter pub get

# 4. Instalar CocoaPods (fundamental para el error de 'Generated.xcconfig')
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
cd ..
pod install

exit 0
