using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SST.Domain.Security.Entities;

namespace SST.Infrastructure.Persistence.Seed;

/// <summary>
/// Bootstrap opcional para crear o restablecer el acceso SUPER_ADMIN.
///
/// Solo se ejecuta cuando existen las variables de entorno:
/// SST_SUPERADMIN_USER
/// SST_SUPERADMIN_PASSWORD
///
/// Esto evita dejar una contraseña fija escrita en el código.
/// </summary>
public static class SuperAdminBootstrap
{
    public static async Task EjecutarAsync(
        SSTDbContext context,
        CancellationToken cancellationToken = default)
    {
        string? nombreUsuario =
            Environment.GetEnvironmentVariable("SST_SUPERADMIN_USER");

        string? password =
            Environment.GetEnvironmentVariable("SST_SUPERADMIN_PASSWORD");

        if (string.IsNullOrWhiteSpace(nombreUsuario) ||
            string.IsNullOrWhiteSpace(password))
        {
            return;
        }

        nombreUsuario = nombreUsuario.Trim().ToLowerInvariant();

        // =========================================================
        // 1. GARANTIZAR ROL SUPER_ADMIN
        // =========================================================

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

            await context.SaveChangesAsync(cancellationToken);
        }
        else
        {
            rolSuperAdmin.Activo = true;
            rolSuperAdmin.EsGlobal = true;
        }

        // =========================================================
        // 2. BUSCAR USUARIO
        // =========================================================

        Usuario? usuario =
            await context.Usuarios
                .Include(x => x.UsuariosRoles)
                .FirstOrDefaultAsync(
                    x =>
                        x.NombreUsuario.ToLower() == nombreUsuario &&
                        x.Estado,
                    cancellationToken);

        // =========================================================
        // 3. CREAR USUARIO SI NO EXISTE
        // =========================================================

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

                // Se mantiene InstitucionId = 1 porque el proyecto
                // actual utiliza esa institución base.
                InstitucionId = 1,

                Activo = true,
                Estado = true,
                DebeCambiarPassword = true,
                FechaRegistro = DateTime.UtcNow,
                UsuarioRegistroId = 1
            };

            var hasher = new PasswordHasher<Usuario>();

            usuario.PasswordHash =
                hasher.HashPassword(
                    usuario,
                    password);

            context.Usuarios.Add(usuario);

            await context.SaveChangesAsync(cancellationToken);
        }
        else
        {
            // =====================================================
            // 4. RESTABLECER CONTRASEÑA Y ACTIVAR
            // =====================================================

            usuario.Activo = true;
            usuario.Estado = true;
            usuario.DebeCambiarPassword = true;
            usuario.FechaActualizacion = DateTime.UtcNow;
            usuario.UsuarioActualizacionId = usuario.Id;

            var hasher = new PasswordHasher<Usuario>();

            usuario.PasswordHash =
                hasher.HashPassword(
                    usuario,
                    password);
        }

        // =========================================================
        // 5. GARANTIZAR RELACIÓN USUARIO -> SUPER_ADMIN
        // =========================================================

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
            relacion.FechaActualizacion = DateTime.UtcNow;
            relacion.UsuarioActualizacionId = usuario.Id;
        }

        await context.SaveChangesAsync(cancellationToken);
    }
}
