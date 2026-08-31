# Operación y sincronización offline

## Objetivo

Permitir que SST EduRisk continúe trabajando cuando el celular no tiene acceso al backend.

## Sesión offline

El usuario debe haber iniciado sesión correctamente al menos una vez con conexión. La aplicación guarda de forma segura la información necesaria para autorizar posteriores ingresos offline.

La contraseña nunca debe almacenarse en texto plano.

## Datos locales

SQLite conserva catálogos y registros operativos requeridos por las pantallas offline.

## Flujo de creación

```text
Usuario crea registro
        |
        v
Guardar en SQLite
        |
        v
Marcar pendiente
        |
        v
Registrar operación en cola
        |
   sin internet
        |
        v
Mantener local
        |
 vuelve internet
        v
Enviar al backend
        |
        v
Guardar idServidor
        |
        v
Marcar sincronizado
```

## Entidades validadas en modo offline

- Matrices IPERC.
- Detalles IPERC.
- Seguimientos IPERC.
- Mapas de riesgo.
- Catálogos precargados.
- Reportes basados en información disponible localmente.

## Reglas importantes

- No eliminar SQLite al actualizar el APK.
- Actualizar el APK con `adb install -r` durante pruebas.
- No crear duplicados al reintentar sincronización.
- Conservar el identificador local hasta finalizar sincronización.
- Registrar errores de sincronización sin perder los datos locales.
- Una eliminación offline debe propagarse al servidor cuando vuelva la conexión.
- Las operaciones pendientes deben ser idempotentes o disponer de mecanismos equivalentes de control de duplicidad.

## Prueba mínima

1. Iniciar sesión online.
2. Precargar catálogos.
3. Apagar backend o desconectar red.
4. Ingresar offline.
5. Crear matriz, detalle y seguimiento.
6. Confirmar que aparecen localmente.
7. Restaurar backend.
8. Ejecutar/esperar sincronización.
9. Verificar los registros en MySQL.
10. Confirmar que no existen duplicados.