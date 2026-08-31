# Checklist final de entrega

## Código

- [ ] `flutter analyze` sin errores.
- [ ] `dotnet build` sin errores.
- [ ] Cambios finales comprometidos.
- [ ] `git push origin main` completado.
- [ ] `git status` limpio.
- [ ] No hay scripts temporales dentro del commit final.

## Seguridad

- [ ] `android/key.properties` no está versionado.
- [ ] Ningún `.jks` o `.keystore` está versionado.
- [ ] `release_backup/` no está versionado.
- [ ] No hay contraseñas en archivos públicos.
- [ ] Secretos JWT y conexión de producción están fuera del repositorio.

## Android

- [ ] APK release generado.
- [ ] Firma APK verificada.
- [ ] AAB release generado.
- [ ] Firma AAB verificada.
- [ ] `versionName` correcto.
- [ ] `versionCode` correcto.
- [ ] APK instalado en dispositivo real.
- [ ] Actualización con `adb install -r` conserva datos.

## Funcional

- [ ] Login online.
- [ ] Acceso offline autorizado.
- [ ] Roles probados.
- [ ] Matrices IPERC.
- [ ] Detalles IPERC.
- [ ] Matriz 5x5.
- [ ] Seguimientos.
- [ ] Mapas de riesgo.
- [ ] Reportes PDF.
- [ ] Reportes Excel.
- [ ] Gráficos.
- [ ] Rotación de vista previa.
- [ ] Sincronización offline-online.
- [ ] Eliminaciones offline sincronizadas.
- [ ] Sin duplicados.

## Datos

- [ ] MySQL respaldado.
- [ ] Datos maestros presentes.
- [ ] Claves foráneas válidas.
- [ ] Operaciones pendientes en SQLite revisadas.

## Respaldo

- [ ] APK final respaldado.
- [ ] AAB final respaldado.
- [ ] JKS respaldado en dos ubicaciones seguras.
- [ ] SHA-256 de APK guardado.
- [ ] SHA-256 de AAB guardado.
- [ ] Alias y credenciales de firma conservados de manera segura.

## Producción

- [ ] Definir servidor definitivo.
- [ ] Sustituir IP LAN fija.
- [ ] Configurar HTTPS.
- [ ] Definir dominio/DNS.
- [ ] Configurar MySQL de producción.
- [ ] Configurar secretos de producción.
- [ ] Configurar respaldo automático de MySQL.
- [ ] Configurar monitoreo y logs.
- [ ] Realizar prueba piloto.
- [ ] Definir responsable de soporte.

## Documentación

- [ ] README revisado.
- [ ] Arquitectura revisada.
- [ ] Instalación revisada.
- [ ] Base de datos revisada.
- [ ] Modo offline revisado.
- [ ] Roles revisados.
- [ ] Seguridad revisada.
- [ ] Release revisado.
- [ ] Pruebas revisadas.
- [ ] Respaldo revisado.
- [ ] Operación y soporte revisados.