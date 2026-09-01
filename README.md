# SST EduRisk

Aplicación móvil para la gestión de Seguridad y Salud en el Trabajo (SST) e IPERC en instituciones educativas.

## Estado de la versión

- Aplicación: SST EduRisk
- Versión Flutter: 2.0.0+2
- Backend: ASP.NET Core .NET 10
- Base de datos servidor: MySQL
- Base de datos móvil: SQLite
- Plataforma principal: Android
- Operación: online y offline
- Artefactos de entrega: APK release y AAB release firmados

## Funcionalidades principales

- Inicio de sesión y autorización por roles.
- Gestión de instituciones, sedes, áreas, puestos, procesos y actividades.
- Gestión de categorías y tipos de peligro.
- Gestión de peligros, consecuencias, controles y EPP.
- Matrices IPERC.
- Detalles IPERC y evaluación de riesgo.
- Matriz de riesgo 5x5.
- Seguimientos IPERC.
- Mapas de riesgo con plano y marcadores.
- Reportes con PDF, Excel y gráficos.
- Trabajo offline con SQLite.
- Cola de cambios y sincronización al recuperar conexión.
- Generación de APK/AAB release firmados.

## Arquitectura

```text
SST-IPERC-COLEGIO/
├── backend/
│   └── SST_Backend/
│       └── src/
│           ├── SST.Api
│           ├── SST.Application
│           ├── SST.Domain
│           └── SST.Infrastructure
├── mobile/
│   └── sst_mobile/
│       ├── android/
│       ├── assets/
│       └── lib/
│           ├── core/
│           ├── data/
│           ├── domain/
│           └── presentation/
├── docs/
└── .gitignore
```

## Inicio rápido de desarrollo

Backend:

```powershell
cd backend\SST_Backend\src\SST.Api
dotnet restore
dotnet run --urls "http://0.0.0.0:5006"
```

Flutter:

```powershell
cd mobile\sst_mobile
flutter pub get
flutter analyze
flutter run
```

## Configuración de API

La versión actual de pruebas de red local usa:

```text
http://192.168.18.23:5006/api
```

Esta dirección es apropiada únicamente para el entorno local actual. Para una distribución real fuera de esa red debe reemplazarse por una URL estable del backend y utilizar HTTPS.

## Seguridad de firma Android

Nunca almacenar en Git:

```text
android/key.properties
*.jks
*.keystore
release_backup/
```

La clave de firma original debe mantenerse en respaldo seguro. Las futuras actualizaciones Android deben firmarse con la misma clave.

## Documentación

Consultar la carpeta `docs/` para arquitectura, instalación, base de datos, modo offline, roles, seguridad, pruebas, operación, release, respaldo y checklist de entrega.

## Configuración del backend por entorno

<!-- API_BASE_URL_DART_DEFINE_DOC_V1 -->

La URL del backend se define en compilación mediante `API_BASE_URL`.

Sin parámetro, la aplicación conserva el backend LAN de desarrollo:

```text
http://192.168.18.23:5006/api
```

Para ejecutar contra otro servidor:

```powershell
flutter run --dart-define=API_BASE_URL=https://servidor.example.com/api
```

Para generar un release de producción:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com/api
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.com/api
```

La URL de producción debe usar HTTPS y ser accesible desde los dispositivos donde se instalará SST EduRisk.
