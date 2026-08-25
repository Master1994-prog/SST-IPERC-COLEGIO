using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SST.Domain.Security.Entities;

namespace SST.Infrastructure.Persistence.Seed;

/// <summary>
/// Bootstrap opcional del SUPER_ADMIN.
///
/// Variables:
/// SST_SUPERADMIN_USER
/// SST_SUPERADMIN_PASSWORD
///
/// IMPORTANTE:
/// Un usuario SUPER_ADMIN existente YA NO recibe una contraseña
/// nueva cada vez que arranca la API.
///
/// Para un restablecimiento de emergencia se puede usar:
/// SST_SUPERADMIN_FORCE_RESET=true
/// </summary>
public static class SuperAdminBootstrap
{
    public static async Task EjecutarAsync(
        SSTDbContext context,
        CancellationToken cancellationToken = default)
    {
        string? nombreUsuario =
            Environment.GetEnvironmentVariable(
                "SST_SUPERADMIN_USER");

        string? password =
            Environment.GetEnvironmentVariable(
                "SST_SUPERADMIN_PASSWORD");

        if (string.IsNullOrWhiteSpace(nombreUsuario) ||
            string.IsNullOrWhiteSpace(password))
        {
            return;
        }

        nombreUsuario =
            nombreUsuario.Trim().ToLowerInvariant();

        string? forzarResetTexto =
            Environment.GetEnvironmentVariable(
                "SST_SUPERADMIN_FORCE_RESET");

        bool forzarReset =
            string.Equals(
                forzarResetTexto,
                "true",
                StringComparison.OrdinalIgnoreCase) ||
            forzarResetTexto == "1";

        // =====================================================
        // 1. GARANTIZAR ROL SUPER_ADMIN
        // =====================================================

        Rol? rolSuperAdmin =
            await context.Roles
                .FirstOrDefaultAsync(
                    x =>
                        x.Codigo == "SUPER_ADMIN" &&
                        x.Estado,
                    cancellationToken);

        if (rolSuperAdmin is null)
        {
            rolSuperAdmin = new Rol
            {
                Codigo = "SUPER_ADMIN",
                Nombre = "Super Administrador",
                Descripcion =
                    "Administrador global con acceso total al sistema SST/IPERC.",
                Activo = true,
                EsGlobal = true,
                Estado = true,
                FechaRegistro = DateTime.UtcNow,
                UsuarioRegistroId = 1
            };

            context.Roles.Add(rolSuperAdmin);

            await context.SaveChangesAsync(
                cancellationToken);
        }
        else
        {
            rolSuperAdmin.Activo = true;
            rolSuperAdmin.EsGlobal = true;
        }

        // =====================================================
        // 2. BUSCAR USUARIO
        // =====================================================

        Usuario? usuario =
            await context.Usuarios
                .Include(x => x.UsuariosRoles)
                .FirstOrDefaultAsync(
                    x =>
                        x.NombreUsuario.ToLower() ==
                            nombreUsuario &&
                        x.Estado,
                    cancellationToken);

        var hasher =
            new PasswordHasher<Usuario>();

        // =====================================================
        // 3. CREAR SI NO EXISTE
        // =====================================================

        if (usuario is null)
        {
            usuario = new Usuario
            {
                Nombres = "Super",
                Apellidos = "Administrador",
                NombreUsuario = nombreUsuario,
                Correo = null,
                TipoDocumento = null,
                NumeroDocumento = null,
                Telefono = null,
                InstitucionId = 1,
                Activo = true,
                Estado = true,
                FechaRegistro = DateTime.UtcNow,
                UsuarioRegistroId = 1,
                SesionesDesdeCambioPassword = 0
            };

            string passwordHash =
                hasher.HashPassword(
                    usuario,
                    password);

            usuario.EstablecerPassword(
                passwordHash,
                debeCambiarPassword: true);

            context.Usuarios.Add(usuario);

            await context.SaveChangesAsync(
                cancellationToken);
        }
        else
        {
            // Activar y mantener la contraseña personal actual.
            usuario.Activo = true;
            usuario.Estado = true;

            // Solo restablecer si se solicita explícitamente.
            if (forzarReset)
            {
                string passwordHash =
                    hasher.HashPassword(
                        usuario,
                        password);

                usuario.EstablecerPassword(
                    passwordHash,
                    debeCambiarPassword: true);

                usuario.FechaActualizacion =
                    DateTime.UtcNow;

                usuario.UsuarioActualizacionId =
                    usuario.Id;
            }
        }

        // =====================================================
        // 4. GARANTIZAR RELACIÓN -> SUPER_ADMIN
        // =====================================================

        UsuarioRol? relacion =
            await context.UsuariosRoles
                .FirstOrDefaultAsync(
                    x =>
                        x.UsuarioId == usuario.Id &&
                        x.RolId == rolSuperAdmin.Id,
                    cancellationToken);

        if (relacion is null)
        {
            relacion = new UsuarioRol
            {
                UsuarioId = usuario.Id,
                RolId = rolSuperAdmin.Id,
                Activo = true,
                Estado = true,
                FechaRegistro = DateTime.UtcNow,
                UsuarioRegistroId = usuario.Id
            };

            context.UsuariosRoles.Add(relacion);
        }
        else
        {
            relacion.Activo = true;
            relacion.Estado = true;
            relacion.FechaActualizacion =
                DateTime.UtcNow;
            relacion.UsuarioActualizacionId =
                usuario.Id;
        }

        await context.SaveChangesAsync(
            cancellationToken);
    }
}
