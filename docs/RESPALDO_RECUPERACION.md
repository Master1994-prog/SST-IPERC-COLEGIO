# Respaldo y recuperación

## Código fuente

Repositorio GitHub:

```text
Master1994-prog/SST-IPERC-COLEGIO
```

Antes de una entrega:

```powershell
git status
git log -1 --oneline
git push origin main
```

El estado esperado es:

```text
nothing to commit, working tree clean
```

## Firma Android

Respaldar el JKS en al menos dos ubicaciones seguras.

También conservar de forma segura:

- Alias de la clave.
- Contraseñas correspondientes.
- Identidad del certificado.
- Fecha de creación.
- Huellas SHA-256.

No guardar contraseñas dentro de este repositorio ni dentro de la documentación pública.

## MySQL

Realizar dump antes de cambios importantes o despliegues.

Comprobar periódicamente que el respaldo puede restaurarse.

## Artefactos

Conservar al menos:

```text
APK de la versión entregada
AAB de la versión entregada
SHA-256 del APK
SHA-256 del AAB
JKS utilizado
```

## Recuperación de dispositivo

La información offline que todavía no llegó al servidor puede perderse si se desinstala la aplicación o se borran sus datos. Antes de realizar esas acciones se debe confirmar que no existen operaciones pendientes o disponer de un mecanismo formal de respaldo local.