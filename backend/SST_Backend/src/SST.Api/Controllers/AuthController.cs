using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using SST.Domain.Security.Entities;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SST.Application.Security.DTOs;
using SST.Application.Security.Interfaces;
using SST.Infrastructure.Persistence;

namespace SST.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly SSTDbContext _dbContext;

    private readonly IPasswordHasher<Usuario> _passwordHasher;

    public AuthController(
    IAuthService authService,
    SSTDbContext dbContext,
    IPasswordHasher<Usuario> passwordHasher)
    {
        _authService = authService;
        _dbContext = dbContext;
        _passwordHasher = passwordHasher;
    }

    // =========================================================
    // LOGIN
    // =========================================================

    [HttpPost("login")]
    [ProducesResponseType(
        typeof(LoginResponse),
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status400BadRequest)]
    [ProducesResponseType(
        StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Login(
        [FromBody] LoginRequest request,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
        {
            return ValidationProblem(ModelState);
        }

        LoginResponse? resultado =
            await _authService.LoginAsync(
                request,
                cancellationToken);

        if (resultado is null)
        {
            return Unauthorized(new
            {
                mensaje =
                    "Usuario, contraseña o rol incorrecto."
            });
        }

        return Ok(resultado);
    }

    // =========================================================
    // CAMBIAR CONTRASEÑA DEL USUARIO AUTENTICADO
    // =========================================================

    [HttpPost("cambiar-password-propio")]
    [Authorize]
    [ProducesResponseType(
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status400BadRequest)]
    [ProducesResponseType(
        StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult>
        CambiarPasswordPropio(
            [FromBody]
        CambiarPasswordPropioRequest solicitud,
            CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
        {
            return ValidationProblem(ModelState);
        }

        // -----------------------------------------------------
        // OBTENER USUARIO DESDE EL TOKEN
        // -----------------------------------------------------

        string? usuarioIdTexto =
            User.FindFirstValue(
                ClaimTypes.NameIdentifier);

        if (!long.TryParse(
                usuarioIdTexto,
                out long usuarioId) ||
            usuarioId <= 0)
        {
            return Unauthorized(new
            {
                mensaje =
                    "No se pudo identificar al usuario autenticado."
            });
        }

        Usuario? usuario =
            await _dbContext
                .Usuarios
                .FirstOrDefaultAsync(
                    item =>
                        item.Id == usuarioId &&
                        item.Estado &&
                        item.Activo,
                    cancellationToken);

        if (usuario is null)
        {
            return Unauthorized(new
            {
                mensaje =
                    "La cuenta de usuario no está disponible."
            });
        }

        // -----------------------------------------------------
        // VALIDAR CONTRASEÑA ACTUAL
        // -----------------------------------------------------

        PasswordVerificationResult resultadoActual =
            _passwordHasher.VerifyHashedPassword(
                usuario,
                usuario.PasswordHash,
                solicitud.PasswordActual);

        if (resultadoActual ==
            PasswordVerificationResult.Failed)
        {
            return BadRequest(new
            {
                mensaje =
                    "La contraseña actual no es correcta."
            });
        }

        // -----------------------------------------------------
        // EVITAR REUTILIZAR LA MISMA CONTRASEÑA
        // -----------------------------------------------------

        PasswordVerificationResult resultadoNueva =
            _passwordHasher.VerifyHashedPassword(
                usuario,
                usuario.PasswordHash,
                solicitud.NuevaPassword);

        if (resultadoNueva !=
            PasswordVerificationResult.Failed)
        {
            return BadRequest(new
            {
                mensaje =
                    "La nueva contraseña debe ser diferente "
                    + "a la contraseña actual."
            });
        }

        // -----------------------------------------------------
        // ACTUALIZAR PASSWORD
        // -----------------------------------------------------

        usuario.PasswordHash =
            _passwordHasher.HashPassword(
                usuario,
                solicitud.NuevaPassword);

        usuario.DebeCambiarPassword = false;

        usuario.FechaActualizacion =
            DateTime.UtcNow;

        usuario.UsuarioActualizacionId =
            usuario.Id;

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Ok(new
        {
            mensaje =
                "Contraseña actualizada correctamente."
        });
    }

    // =========================================================
    // SOLICITAR ACCESO
    // =========================================================

    [HttpPost("solicitar-acceso")]
    [ProducesResponseType(
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> SolicitarAcceso(
        [FromBody] SolicitudAccesoRequest request,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
        {
            return ValidationProblem(ModelState);
        }

        string correo =
            request.Correo
                .Trim()
                .ToLowerInvariant();

        // -----------------------------------------------------
        // EVITAR SOLICITUDES PENDIENTES DUPLICADAS
        // -----------------------------------------------------

        bool existeSolicitudPendiente =
            await _dbContext
                .SolicitudesAcceso
                .AsNoTracking()
                .AnyAsync(
                    solicitud =>
                        solicitud.Correo == correo &&
                        solicitud.EstadoSolicitud ==
                            "PENDIENTE",
                    cancellationToken);

        if (existeSolicitudPendiente)
        {
            return Ok(new
            {
                mensaje =
                    "Ya existe una solicitud de acceso "
                    + "pendiente para este correo electrónico."
            });
        }

        // -----------------------------------------------------
        // VERIFICAR SI YA EXISTE UNA CUENTA
        // -----------------------------------------------------

        bool usuarioExistente =
            await _dbContext
                .Usuarios
                .AsNoTracking()
                .AnyAsync(
                    usuario =>
                        usuario.Estado &&
                        usuario.Correo != null &&
                        usuario.Correo.ToLower() ==
                            correo,
                    cancellationToken);

        if (usuarioExistente)
        {
            return Ok(new
            {
                mensaje =
                    "El correo indicado ya está asociado "
                    + "a una cuenta. Si no recuerda su "
                    + "contraseña, utilice la opción "
                    + "de recuperación."
            });
        }

        var solicitud =
            new SolicitudAcceso
            {
                Nombres =
                    request.Nombres.Trim(),

                Apellidos =
                    request.Apellidos.Trim(),

                Correo =
                    correo,

                Institucion =
                    request.Institucion.Trim(),

                Cargo =
                    LimpiarTexto(
                        request.Cargo),

                Motivo =
                    LimpiarTexto(
                        request.Motivo),

                EstadoSolicitud =
                    "PENDIENTE",

                FechaSolicitud =
                    DateTime.UtcNow
            };

        _dbContext
            .SolicitudesAcceso
            .Add(solicitud);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Ok(new
        {
            mensaje =
                "Solicitud de acceso registrada "
                + "correctamente. Un administrador "
                + "deberá revisarla antes de habilitar "
                + "su cuenta."
        });
    }

    // =========================================================
    // RECUPERAR CONTRASEÑA
    // =========================================================

    [HttpPost("recuperar-password")]
    [ProducesResponseType(
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> RecuperarPassword(
        [FromBody] RecuperarPasswordRequest request,
        CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
        {
            return ValidationProblem(ModelState);
        }

        string identificador =
            request.Identificador
                .Trim()
                .ToLowerInvariant();

        // -----------------------------------------------------
        // BUSCAR POR USUARIO O CORREO
        // -----------------------------------------------------

        Usuario? usuario =
            await _dbContext
                .Usuarios
                .AsNoTracking()
                .FirstOrDefaultAsync(
                    item =>
                        item.Estado &&
                        item.Activo &&
                        (
                            item.NombreUsuario
                                .ToLower() ==
                                identificador ||
                            (
                                item.Correo != null &&
                                item.Correo
                                    .ToLower() ==
                                    identificador
                            )
                        ),
                    cancellationToken);

        // -----------------------------------------------------
        // NO REVELAR SI LA CUENTA EXISTE O NO
        // -----------------------------------------------------
        //
        // Solo registramos solicitud cuando encontramos usuario,
        // pero siempre devolvemos el mismo mensaje.
        // -----------------------------------------------------

        if (usuario is not null)
        {
            bool pendiente =
                await _dbContext
                    .SolicitudesRecuperacionPassword
                    .AsNoTracking()
                    .AnyAsync(
                        solicitud =>
                            solicitud.UsuarioId ==
                                usuario.Id &&
                            solicitud.EstadoSolicitud ==
                                "PENDIENTE",
                        cancellationToken);

            if (!pendiente)
            {
                var solicitud =
                    new SolicitudRecuperacionPassword
                    {
                        UsuarioId =
                            usuario.Id,

                        Identificador =
                            identificador,

                        Correo =
                            usuario.Correo,

                        EstadoSolicitud =
                            "PENDIENTE",

                        FechaSolicitud =
                            DateTime.UtcNow
                    };

                _dbContext
                    .SolicitudesRecuperacionPassword
                    .Add(solicitud);

                await _dbContext
                    .SaveChangesAsync(
                        cancellationToken);
            }
        }

        return Ok(new
        {
            mensaje =
                "Si los datos corresponden a una "
                + "cuenta registrada, se ha generado "
                + "una solicitud de recuperación. "
                + "El administrador del sistema podrá "
                + "restablecer el acceso."
        });
    }

    // =========================================================
    // UTILIDAD
    // =========================================================

    private static string? LimpiarTexto(
        string? valor)
    {
        if (string.IsNullOrWhiteSpace(valor))
        {
            return null;
        }

        return valor.Trim();
    }
}