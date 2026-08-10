BLOQUE SEGURIDAD REAL DE ROLES - BACKEND
=======================================

Este bloque NO reemplaza archivos completos del proyecto.
Aplica cambios puntuales y crea copias .bak antes de modificar.

ARCHIVOS MODIFICADOS
---------------------
1. src\SST.Infrastructure\Security\AuthService.cs
2. src\SST.Api\Controllers\UsuariosController.cs
3. src\SST.Api\Controllers\RolesController.cs

CAMBIOS
-------
AuthService:
- JWT usa Rol.Codigo en vez de Rol.Nombre.
- Ejemplos: SUPER_ADMIN, ADMIN, SUP_TITULAR.

UsuariosController:
- Solo SUPER_ADMIN y ADMIN.

RolesController:
- GET: SUPER_ADMIN y ADMIN.
  ADMIN necesita leer roles para poder crear/editar usuarios.
- POST/PUT/PATCH/DELETE: solo SUPER_ADMIN.

EJECUCIÓN
---------
1. Extrae esta carpeta.
2. Abre PowerShell.
3. Ejecuta:

Set-ExecutionPolicy -Scope Process Bypass

.\APLICAR_SEGURIDAD_ROLES.ps1

4. Luego:

cd D:\Proyectos\SST-IPERC-COLEGIO\backend\SST_Backend
dotnet build

5. Si compila sin errores:

dotnet run --project .\src\SST.Api\SST.Api.csproj

6. Cierra sesión en Flutter e inicia sesión de nuevo para obtener un JWT nuevo.

RESPALDO
--------
El script crea:
AuthService.cs.bak
UsuariosController.cs.bak
RolesController.cs.bak

Si algo no coincide con tu proyecto, el script se detiene en lugar de continuar a ciegas.
