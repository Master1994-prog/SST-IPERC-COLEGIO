$ErrorActionPreference = "Stop"

$repoRoot = "D:\Proyectos\SST-IPERC-COLEGIO"
$backendRoot = Join-Path $repoRoot "backend\SST_Backend"

$authService = Join-Path $backendRoot "src\SST.Infrastructure\Security\AuthService.cs"
$usuariosController = Join-Path $backendRoot "src\SST.Api\Controllers\UsuariosController.cs"
$rolesController = Join-Path $backendRoot "src\SST.Api\Controllers\RolesController.cs"

$files = @($authService, $usuariosController, $rolesController)

foreach ($file in $files) {
    if (-not (Test-Path $file)) {
        throw "No se encontró el archivo: $file"
    }

    Copy-Item $file "$file.bak" -Force
}

function Save-Utf8NoBom {
    param(
        [string]$Path,
        [string]$Content
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

# ============================================================
# 1. AuthService.cs
#    Cambiar los roles del JWT de Rol.Nombre a Rol.Codigo.
# ============================================================

$auth = Get-Content $authService -Raw

$oldRoleSelector = ".Select(x => x.Rol.Nombre)"
$newRoleSelector = ".Select(x => x.Rol.Codigo)"

if ($auth.Contains($oldRoleSelector)) {
    $auth = $auth.Replace($oldRoleSelector, $newRoleSelector)
}
elseif (-not $auth.Contains($newRoleSelector)) {
    throw "No se encontró el selector de rol esperado en AuthService.cs"
}

Save-Utf8NoBom -Path $authService -Content $auth

# ============================================================
# 2. UsuariosController.cs
#    Solo SUPER_ADMIN y ADMIN pueden administrar usuarios.
# ============================================================

$usuarios = Get-Content $usuariosController -Raw

$authorizeUsing = "using Microsoft.AspNetCore.Authorization;"

if (-not $usuarios.Contains($authorizeUsing)) {
    $usuarios = $usuarios.Replace(
        "using Microsoft.AspNetCore.Identity;",
        "using Microsoft.AspNetCore.Authorization;`r`nusing Microsoft.AspNetCore.Identity;"
    )
}

$usuariosClassMarker = "[ApiController]`r`n[Route(""api/[controller]"")]`r`npublic sealed class UsuariosController"

if ($usuarios.Contains($usuariosClassMarker)) {
    $usuarios = $usuarios.Replace(
        $usuariosClassMarker,
        "[ApiController]`r`n[Route(""api/[controller]"")]`r`n[Authorize(Roles = ""SUPER_ADMIN,ADMIN"")]`r`npublic sealed class UsuariosController"
    )
}
elseif (-not $usuarios.Contains('[Authorize(Roles = "SUPER_ADMIN,ADMIN")]')) {
    throw "No se encontró la declaración esperada de UsuariosController."
}

Save-Utf8NoBom -Path $usuariosController -Content $usuarios

# ============================================================
# 3. RolesController.cs
#
# Reglas:
# - Todos los endpoints requieren sesión JWT.
# - GET de roles: SUPER_ADMIN y ADMIN.
#   ADMIN necesita leer roles para crear/editar usuarios.
# - Crear/editar/activar/eliminar roles: solo SUPER_ADMIN.
# ============================================================

$roles = Get-Content $rolesController -Raw

if (-not $roles.Contains($authorizeUsing)) {
    $roles = $roles.Replace(
        "using System.ComponentModel.DataAnnotations;",
        "using System.ComponentModel.DataAnnotations;`r`nusing Microsoft.AspNetCore.Authorization;"
    )
}

$rolesClassMarker = "[ApiController]`r`n[Route(""api/[controller]"")]`r`npublic sealed class RolesController"

if ($roles.Contains($rolesClassMarker)) {
    $roles = $roles.Replace(
        $rolesClassMarker,
        "[ApiController]`r`n[Route(""api/[controller]"")]`r`n[Authorize]`r`npublic sealed class RolesController"
    )
}
elseif (-not $roles.Contains("[Authorize]")) {
    throw "No se encontró la declaración esperada de RolesController."
}

# GET /api/Roles
$getAllMarker = "[HttpGet]`r`n"
if ($roles.Contains($getAllMarker) -and -not $roles.Contains('[HttpGet]`r`n    [Authorize(Roles = "SUPER_ADMIN,ADMIN")]')) {
    $roles = $roles.Replace(
        $getAllMarker,
        "[HttpGet]`r`n    [Authorize(Roles = ""SUPER_ADMIN,ADMIN"")]`r`n",
        1
    )
}

# GET /api/Roles/{id}
$getByIdMarker = '[HttpGet("{id:long}")]'
if ($roles.Contains($getByIdMarker) -and -not $roles.Contains('[HttpGet("{id:long}")]' + "`r`n    " + '[Authorize(Roles = "SUPER_ADMIN,ADMIN")]')) {
    $roles = $roles.Replace(
        $getByIdMarker,
        '[HttpGet("{id:long}")]' + "`r`n    " + '[Authorize(Roles = "SUPER_ADMIN,ADMIN")]'
    )
}

# POST
$postMarker = "[HttpPost]"
if ($roles.Contains($postMarker) -and -not $roles.Contains('[HttpPost]' + "`r`n    " + '[Authorize(Roles = "SUPER_ADMIN")]')) {
    $roles = $roles.Replace(
        $postMarker,
        '[HttpPost]' + "`r`n    " + '[Authorize(Roles = "SUPER_ADMIN")]'
    )
}

# PUT
$putMarker = '[HttpPut("{id:long}")]'
if ($roles.Contains($putMarker) -and -not $roles.Contains($putMarker + "`r`n    " + '[Authorize(Roles = "SUPER_ADMIN")]')) {
    $roles = $roles.Replace(
        $putMarker,
        $putMarker + "`r`n    " + '[Authorize(Roles = "SUPER_ADMIN")]'
    )
}

# PATCH (puede haber uno o más)
$patchMatches = [regex]::Matches($roles, '\[HttpPatch\([^\r\n]+\)\]')
foreach ($m in $patchMatches) {
    $marker = $m.Value
    $full = $marker + "`r`n    " + '[Authorize(Roles = "SUPER_ADMIN")]'
    if (-not $roles.Contains($full)) {
        $roles = $roles.Replace($marker, $full)
    }
}

# DELETE
$deleteMarker = '[HttpDelete("{id:long}")]'
if ($roles.Contains($deleteMarker) -and -not $roles.Contains($deleteMarker + "`r`n    " + '[Authorize(Roles = "SUPER_ADMIN")]')) {
    $roles = $roles.Replace(
        $deleteMarker,
        $deleteMarker + "`r`n    " + '[Authorize(Roles = "SUPER_ADMIN")]'
    )
}

Save-Utf8NoBom -Path $rolesController -Content $roles

Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host "SEGURIDAD DE ROLES APLICADA" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""
Write-Host "AuthService:"
Write-Host "  JWT ahora usa Rol.Codigo"
Write-Host ""
Write-Host "UsuariosController:"
Write-Host "  SUPER_ADMIN + ADMIN"
Write-Host ""
Write-Host "RolesController:"
Write-Host "  GET: SUPER_ADMIN + ADMIN"
Write-Host "  POST/PUT/PATCH/DELETE: SUPER_ADMIN"
Write-Host ""
Write-Host "Se crearon respaldos .bak de los 3 archivos."
Write-Host ""
Write-Host "Ahora ejecuta:"
Write-Host "cd $backendRoot"
Write-Host "dotnet build"
