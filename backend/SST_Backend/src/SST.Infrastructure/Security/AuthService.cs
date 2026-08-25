using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SST.Application.Security.DTOs;
using SST.Application.Security.Interfaces;
using SST.Domain.Security.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Infrastructure.Security;

/// <summary>
/// Servicio de autenticación de SST EduRisk.
/// </summary>
public sealed class AuthService : IAuthService
{
    private readonly SSTDbContext _dbContext;
    private readonly IPasswordHasher<Usuario> _passwordHasher;
    private readonly IJwtService _jwtService;

    public AuthService(
        SSTDbContext dbContext,
        IPasswordHasher<Usuario> passwordHasher,
        IJwtService jwtService)
    {
        _dbContext = dbContext;
        _passwordHasher = passwordHasher;
        _jwtService = jwtService;
    }

    /// <summary>
    /// Valida las credenciales, registra una sesión online,
    /// aplica la política de 30 sesiones y genera el JWT.
    /// </summary>
    public async Task<LoginResponse?> LoginAsync(
        LoginRequest request,
        CancellationToken cancellationToken = default)
    {
        string identificador =
            request.Usuario.Trim().ToLowerInvariant();

        if (string.IsNullOrWhiteSpace(identificador) ||
            string.IsNullOrWhiteSpace(request.Password))
        {
            return null;
        }

        Usuario? usuario =
            await _dbContext.Usuarios
                .Include(x => x.UsuariosRoles)
                    .ThenInclude(x => x.Rol)
                .FirstOrDefaultAsync(
                    x =>
                        x.Estado &&
                        x.Activo &&
                        (
                            x.NombreUsuario.ToLower() == identificador ||
                            (
                                x.Correo != null &&
                                x.Correo.ToLower() == identificador
                            )
                        ),
                    cancellationToken);

        if (usuario is null)
        {
            return null;
        }

        PasswordVerificationResult resultado =
            _passwordHasher.VerifyHashedPassword(
                usuario,
                usuario.PasswordHash,
                request.Password);

        if (resultado ==
            PasswordVerificationResult.Failed)
        {
            return null;
        }

        List<string> roles =
            usuario.UsuariosRoles
                .Where(x =>
                    x.Estado &&
                    x.Activo &&
                    x.Rol.Estado &&
                    x.Rol.Activo)
                .Select(x => x.Rol.Codigo)
                .Where(codigo =>
                    !string.IsNullOrWhiteSpace(codigo))
                .Select(codigo =>
                    codigo.Trim().ToUpperInvariant())
                .Distinct()
                .ToList();

        if (roles.Count == 0)
        {
            return null;
        }

        // ---------------------------------------------------------
        // REHASH
        // ---------------------------------------------------------
        // Si ASP.NET Identity recomienda actualizar el hash,
        // lo hacemos sin modificar la política de sesiones.
        // ---------------------------------------------------------
        if (resultado ==
            PasswordVerificationResult.SuccessRehashNeeded)
        {
            usuario.PasswordHash =
                _passwordHasher.HashPassword(
                    usuario,
                    request.Password);
        }

        // ---------------------------------------------------------
        // REGISTRAR SESIÓN ONLINE
        // ---------------------------------------------------------
        //
        // Comportamiento definido en Usuario.RegistrarAcceso():
        //
        // - contraseña temporal pendiente:
        //      no incrementa el contador;
        //
        // - sesiones 1..29:
        //      incrementa normalmente;
        //
        // - sesión 30:
        //      contador = 30;
        //      DebeCambiarPassword = true.
        //
        // El modo offline NO pasa por este método y por tanto
        // no incrementa el contador.
        // ---------------------------------------------------------
        usuario.RegistrarAcceso();

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        // ---------------------------------------------------------
        // JWT
        // ---------------------------------------------------------
        //
        // Incluso cuando el cambio de contraseña es obligatorio,
        // se genera un token válido para que Flutter pueda llamar
        // al endpoint de cambio de contraseña propio.
        // ---------------------------------------------------------
        string token =
            _jwtService.GenerarToken(
                usuario,
                roles,
                out DateTime expiraEn);

        return new LoginResponse
        {
            Token = token,
            ExpiraEn = expiraEn,

            Usuario = new UsuarioLoginResponse
            {
                Id = usuario.Id,
                NombreUsuario =
                    usuario.NombreUsuario,
                Nombres =
                    usuario.Nombres,
                Apellidos =
                    usuario.Apellidos,
                Correo =
                    usuario.Correo,

                InstitucionId =
                    usuario.InstitucionId,
                SedeId =
                    usuario.SedeId,
                AreaId =
                    usuario.AreaId,

                DebeCambiarPassword =
                    usuario.DebeCambiarPassword,

                SesionesDesdeCambioPassword =
                    usuario.SesionesDesdeCambioPassword,

                SesionesRestantesCambioPassword =
                    usuario.SesionesRestantesCambioPassword,

                RecordarCambioPassword =
                    usuario.DebeRecordarCambioPassword,

                Roles = roles
            }
        };
    }
}
