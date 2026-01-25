
#!/bin/bash

# 1. Bajamos a la raíz del proyecto
cd ..

# 2. Clonamos Flutter solo si no existe la carpeta
if [ ! -d "flutter" ]; then
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# 3. Configuramos la ruta usando una variable limpia
export PATH="$PATH:$(pwd)/flutter/bin"

# 4. Forzamos a que Flutter se reconozca y prepare
flutter precache --ios
flutter pub get

# 5. Volvemos a la carpeta de iOS e instalamos dependencias
cd ios
pod install

