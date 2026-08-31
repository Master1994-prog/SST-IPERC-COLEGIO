# Seguridad

## Credenciales

- No almacenar contraseñas en texto plano.
- Utilizar almacenamiento seguro del dispositivo para datos sensibles.
- Los secretos del backend no deben estar dentro del repositorio.
- Rotar secretos si alguna vez se publican por accidente.

## Firma Android

Archivos privados:

```text
android/key.properties
sst-edurisk-release.jks
```

La clave JKS no debe enviarse por correo sin protección ni almacenarse públicamente.

La pérdida de la clave puede impedir publicar una actualización compatible con instalaciones existentes, dependiendo del canal de distribución y la administración de claves usada.

## API

La configuración actual usa HTTP dentro de una LAN de pruebas. Para producción:

- Hospedar el backend en una dirección estable.
- Utilizar HTTPS con certificado válido.
- Evitar IP privadas fijas embebidas en la aplicación final.
- Separar configuración de desarrollo, pruebas y producción.
- Restringir CORS.
- Implementar registro y monitoreo de fallos.
- Aplicar rate limiting donde sea apropiado.
- Mantener dependencias actualizadas.

## JWT / autorización

- Validar expiración y firma del token.
- Verificar roles en endpoints protegidos.
- No confiar únicamente en permisos de interfaz.

## Datos locales

SQLite puede contener información de trabajo. Para una futura versión de producción se debe evaluar cifrado de datos locales según la sensibilidad real de la información y los requisitos de la institución.