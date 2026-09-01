# Despliegue de produccion - SST EduRisk

## Seguridad prioritaria

El repositorio llego a contener una cadena de conexion y una clave JWT dentro
de `appsettings.json`. Aunque ya no aparezcan en la rama actual, deben
considerarse expuestas porque pueden existir en el historial Git.

Antes de produccion:

1. Cambiar la contrasena del usuario MySQL afectado.
2. Generar una nueva clave JWT aleatoria de al menos 32 bytes.
3. No reutilizar las credenciales antiguas.
4. Mantener las nuevas credenciales fuera de Git.

## Variables de entorno

```text
ASPNETCORE_ENVIRONMENT=Production
ASPNETCORE_URLS=http://127.0.0.1:5006
ConnectionStrings__DefaultConnection=<SECRETO>
Jwt__Key=<SECRETO>
Jwt__Issuer=SST.Api
Jwt__Audience=SST.Mobile
Jwt__ExpirationMinutes=120
Database__RunSeedOnStartup=false
AllowedHosts=api.midominio.com
```

Para un cliente web futuro:

```text
Cors__AllowedOrigins__0=https://panel.midominio.com
```

Flutter Android nativo no depende del CORS del navegador.

## MySQL

- No usar root para la aplicacion.
- Crear usuario dedicado.
- Dar solo permisos necesarios.
- No publicar 3306 a Internet.
- Respaldar y probar restauracion antes de migraciones.

## Publicacion .NET

```powershell
cd backend\SST_Backend

dotnet restore
dotnet build -c Release

dotnet publish .\src\SST.Api\SST.Api.csproj `
  -c Release `
  -o .\publish
```

## Arquitectura recomendada

```text
Internet
   |
   | 443 HTTPS
   v
IIS / Nginx / Apache / proxy
   |
   | HTTP interno 127.0.0.1:5006
   v
SST.Api
   |
   v
MySQL privado
```

## DNS y HTTPS

Usar un dominio estable, por ejemplo:

```text
api.midominio.com
```

Configurar certificado TLS valido.

## Firewall

Exponer:

```text
443/tcp
80/tcp opcional para redireccion
```

No exponer:

```text
3306/tcp
5006/tcp
```

## Persistencia de mapas de riesgo

Los planos actuales viven en:

```text
SST.Api/wwwroot/uploads/mapas-riesgo
```

`wwwroot/uploads` debe persistir entre despliegues y tener respaldo propio.

## Health check

```text
GET /health
```

Respuesta:

```json
{
  "status": "ok",
  "service": "SST.Api"
}
```

## Swagger

Swagger/OpenAPI interactivo queda habilitado solo en Development.

## Flutter contra produccion

```powershell
flutter build apk --release `
  --dart-define=API_BASE_URL=https://api.midominio.com/api

flutter build appbundle --release `
  --dart-define=API_BASE_URL=https://api.midominio.com/api
```

## Prueba posterior al despliegue

1. /health.
2. Login.
3. Catalogos.
4. Matrices IPERC.
5. Detalles y matriz 5x5.
6. Seguimientos.
7. Mapas y planos.
8. Reportes.
9. Prueba offline.
10. Reconexion y sincronizacion.
11. Verificacion MySQL.
12. Confirmar ausencia de duplicados.
13. Revisar logs.

## Operacion minima

- backup automatico de MySQL;
- backup de wwwroot/uploads;
- prueba periodica de restauracion;
- monitoreo de /health;
- rotacion de logs;
- alertas;
- control de espacio;
- actualizaciones de seguridad.

## Checklist

- [ ] Credenciales antiguas rotadas.
- [ ] Secretos fuera de Git.
- [ ] Usuario MySQL dedicado.
- [ ] Backup MySQL probado.
- [ ] Backup uploads probado.
- [ ] Dominio/DNS.
- [ ] HTTPS.
- [ ] 3306 no publico.
- [ ] 5006 no publico.
- [ ] Seed desactivado en produccion.
- [ ] AllowedHosts configurado.
- [ ] /health monitoreado.
- [ ] APK/AAB con URL HTTPS.
- [ ] Online/offline/reconexion probado.