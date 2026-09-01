# Operación y soporte

## Inicio backend local

```powershell
cd backend\SST_Backend\src\SST.Api
dotnet run --urls "http://0.0.0.0:5006"
```

Comprobar:

```powershell
Test-NetConnection 192.168.18.23 -Port 5006
```

## Diagnóstico de conexión móvil

Revisar:

- Celular y servidor en una red que permita comunicación.
- IP del servidor.
- Puerto 5006.
- Firewall de Windows.
- Backend ejecutándose.
- `ApiConfig.baseUrl`.
- Permiso Android de Internet.
- HTTP cleartext únicamente en ambiente donde se haya decidido permitirlo.

## Cambio de red

La IP `192.168.18.23` es una configuración de pruebas. Si el servidor cambia de IP, el APK actual puede dejar de encontrar el backend.

Para producción se recomienda una URL DNS estable con HTTPS y configuración separada por ambiente.

## Fallos offline

Si un registro no sincroniza:

1. No borrar la app.
2. No limpiar datos.
3. Mantener SQLite.
4. Revisar cola de sincronización.
5. Revisar logs del backend.
6. Corregir la causa.
7. Reintentar sincronización.
8. Verificar MySQL.

## Configuración de API por ambiente

<!-- API_BASE_URL_DART_DEFINE_OPERACION_V1 -->

`ApiConfig.baseUrl` utiliza la variable de compilación `API_BASE_URL`.

Ejemplos:

```powershell
# Desarrollo LAN actual
flutter run

# Servidor de pruebas
flutter run --dart-define=API_BASE_URL=https://pruebas.example.com/api

# Producción
flutter run --release --dart-define=API_BASE_URL=https://api.example.com/api
```

Esto evita modificar el código fuente cada vez que cambia el servidor.

Para un despliegue real, no utilizar la IP privada LAN como endpoint de producción.
