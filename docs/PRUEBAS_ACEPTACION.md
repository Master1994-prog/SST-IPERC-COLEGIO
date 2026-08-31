# Plan de pruebas de aceptación

## Prueba online

Validar:

- Login.
- Permisos de cada rol.
- Catálogos.
- Matrices IPERC.
- Detalles.
- Evaluación 5x5.
- Seguimientos.
- Mapas.
- Reportes.
- PDF.
- Excel.
- Rotación de vista previa PDF.
- Sincronización sin pendientes.

## Prueba offline

Con una sesión autorizada previamente:

- Apagar backend.
- Confirmar ingreso offline.
- Abrir catálogos precargados.
- Crear matriz.
- Crear detalle.
- Crear seguimiento.
- Operar mapas.
- Abrir reportes disponibles.
- Verificar registros pendientes.

## Reconexión

- Restaurar backend.
- Confirmar sincronización.
- Verificar MySQL.
- Confirmar ausencia de duplicados.
- Confirmar que los pendientes cambian a sincronizados.

## Prueba de actualización de APK

- Tener datos locales.
- Instalar nueva compilación mediante `adb install -r`.
- Abrir la app.
- Confirmar que SQLite conserva los datos.
- Confirmar login y sincronización.

## Prueba de reportes

- Abrir reporte general.
- Generar vista previa.
- Esperar carga completa.
- Rotar vertical/horizontal varias veces.
- Compartir o imprimir cuando aplique.
- Verificar gráficos lineales y circulares.
- Probar con backend disponible y no disponible.

## Criterio de aceptación

Una versión se considera candidata a entrega únicamente si:

- `flutter analyze` no reporta errores.
- `dotnet build` finaliza correctamente.
- APK y AAB se generan.
- La firma se verifica.
- Flujo online/offline/reconexión funciona.
- No se pierden registros locales.
- Git está limpio.
- No existen secretos versionados.