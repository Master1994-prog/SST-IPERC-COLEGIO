# Instalación del entorno de desarrollo

## Requisitos

### Backend

- Windows 10/11.
- .NET SDK 10.
- MySQL Server.
- MySQL Workbench recomendado.
- Git.

### Aplicación móvil

- Flutter estable compatible con Dart 3.12.2 o superior dentro de las restricciones del proyecto.
- Android SDK.
- Android Platform Tools.
- JDK.
- Dispositivo Android o emulador.
- VS Code o Android Studio.

## Clonar repositorio

```powershell
git clone https://github.com/Master1994-prog/SST-IPERC-COLEGIO.git
cd SST-IPERC-COLEGIO
```

## Backend

```powershell
cd backend\SST_Backend
dotnet restore
dotnet build
```

Ejecución:

```powershell
cd src\SST.Api
dotnet run --urls "http://0.0.0.0:5006"
```

Comprobar puerto:

```powershell
Test-NetConnection 127.0.0.1 -Port 5006
```

## Flutter

```powershell
cd mobile\sst_mobile
flutter pub get
flutter doctor
flutter analyze
```

Con dispositivo conectado:

```powershell
flutter devices
flutter run
```

## Configuración privada

No se deben versionar credenciales ni secretos. Los archivos de configuración de desarrollo y firma están excluidos mediante `.gitignore`.

La cadena de conexión MySQL y los secretos JWT deben configurarse de forma privada en el entorno de ejecución correspondiente.