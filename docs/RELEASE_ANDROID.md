# Release Android

## Versión

```text
versionName: 2.0.0
versionCode: 2
```

Definido en Flutter como:

```text
2.0.0+2
```

## APK

Generar:

```powershell
cd mobile\sst_mobile
flutter analyze
flutter build apk --release
```

Salida:

```text
build\app\outputs\flutter-apk\app-release.apk
```

## AAB

Generar:

```powershell
flutter build appbundle --release
```

Salida:

```text
build\app\outputs\bundle\release\app-release.aab
```

## Firma

El proyecto usa `android/key.properties` cuando está disponible para cargar la firma release.

El JKS se mantiene fuera del repositorio.

Verificación APK:

```powershell
$ApkSigner = "$env:LOCALAPPDATA\Android\Sdk\build-tools\37.0.0\apksigner.bat"
& $ApkSigner verify --verbose --print-certs ".\build\app\outputs\flutter-apk\app-release.apk"
```

Verificación AAB:

```powershell
$JarSigner = "C:\Program Files\Java\jdk-25\bin\jarsigner.exe"
& $JarSigner -verify -verbose -certs ".\build\app\outputs\bundle\release\app-release.aab"
```

## Instalación de actualización APK

No desinstalar durante una prueba de persistencia offline.

```powershell
$Adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $Adb install -r ".\build\app\outputs\flutter-apk\app-release.apk"
```

## Respaldo privado

Ejemplo:

```text
release_backup/
├── SST-EduRisk-2.0.0.apk
├── SST-EduRisk-2.0.0.aab
└── sst-edurisk-release.jks
```

`release_backup/` está excluido de Git.

## URL del backend en el artefacto release

<!-- API_BASE_URL_DART_DEFINE_RELEASE_V1 -->

El APK/AAB incorpora la URL indicada al compilar.

Desarrollo LAN:

```powershell
flutter build apk --release
```

Producción:

```powershell
flutter build apk --release `
  --dart-define=API_BASE_URL=https://api.example.com/api

flutter build appbundle --release `
  --dart-define=API_BASE_URL=https://api.example.com/api
```

Antes de publicar un AAB se debe comprobar qué endpoint se está usando. Un AAB compilado sin `--dart-define=API_BASE_URL=...` seguirá utilizando la IP LAN de desarrollo por defecto.
