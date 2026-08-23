using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SST.Infrastructure.Persistence;

namespace SST.Api.Controllers;

/// <summary>
/// Gestiona las solicitudes de acceso y recuperación
/// de contraseña de SST EduRisk.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "SUPER_ADMIN")]
public sealed class SolicitudesController : ControllerBase
{
    private readonly SSTDbContext _dbContext;

    public SolicitudesController(
        SSTDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    // =========================================================
    // SOLICITUDES DE ACCESO
    // =========================================================

    /// <summary>
    /// Obtiene las solicitudes de acceso.
    /// </summary>
    [HttpGet("acceso")]
    [ProducesResponseType(
        typeof(List<SolicitudAccesoResponseDto>),
        StatusCodes.Status200OK)]
    public async Task<IActionResult> ObtenerSolicitudesAcceso(
        [FromQuery] string? estado,
        CancellationToken cancellationToken)
    {
        IQueryable<SST.Domain.Security.Entities.SolicitudAcceso>
            consulta =
                _dbContext
                    .SolicitudesAcceso
                    .AsNoTracking();

        // -----------------------------------------------------
        // FILTRAR POR ESTADO
        // -----------------------------------------------------

        if (!string.IsNullOrWhiteSpace(estado))
        {
            string estadoNormalizado =
                estado.Trim().ToUpperInvariant();

            consulta =
                consulta.Where(
                    solicitud =>
                        solicitud.EstadoSolicitud ==
                        estadoNormalizado);
        }

        List<SolicitudAccesoResponseDto> solicitudes =
            await consulta
                .OrderByDescending(
                    solicitud =>
                        solicitud.FechaSolicitud)
                .Select(
                    solicitud =>
                        new SolicitudAccesoResponseDto
                        {
                            Id = solicitud.Id,

                            Nombres =
                                solicitud.Nombres,

                            Apellidos =
                                solicitud.Apellidos,

                            Correo =
                                solicitud.Correo,

                            Institucion =
                                solicitud.Institucion,

                            Cargo =
                                solicitud.Cargo,

                            Motivo =
                                solicitud.Motivo,

                            EstadoSolicitud =
                                solicitud.EstadoSolicitud,

                            FechaSolicitud =
                                solicitud.FechaSolicitud,

                            FechaAtencion =
                                solicitud.FechaAtencion
                        })
                .ToListAsync(
                    cancellationToken);

        return Ok(solicitudes);
    }

    // =========================================================
    // CAMBIAR ESTADO SOLICITUD DE ACCESO
    // =========================================================

    [HttpPut("acceso/{id:long}/estado")]
    [ProducesResponseType(
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status400BadRequest)]
    [ProducesResponseType(
        StatusCodes.Status404NotFound)]
    public async Task<IActionResult>
        CambiarEstadoSolicitudAcceso(
            long id,
            [FromBody]
            CambiarEstadoSolicitudAccesoDto solicitud,
            CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return BadRequest(new
            {
                mensaje =
                    "El identificador de la solicitud "
                    + "no es válido."
            });
        }

        string estado =
            solicitud.Estado
                .Trim()
                .ToUpperInvariant();

        // -----------------------------------------------------
        // ESTADOS PERMITIDOS
        // -----------------------------------------------------

        if (estado != "APROBADA" &&
            estado != "RECHAZADA")
        {
            return BadRequest(new
            {
                mensaje =
                    "El estado debe ser APROBADA "
                    + "o RECHAZADA."
            });
        }

        var entidad =
            await _dbContext
                .SolicitudesAcceso
                .FirstOrDefaultAsync(
                    item => item.Id == id,
                    cancellationToken);

        if (entidad is null)
        {
            return NotFound(new
            {
                mensaje =
                    "No se encontró la solicitud "
                    + "de acceso."
            });
        }

        if (entidad.EstadoSolicitud !=
            "PENDIENTE")
        {
            return BadRequest(new
            {
                mensaje =
                    "La solicitud ya fue atendida."
            });
        }

        entidad.EstadoSolicitud = estado;

        entidad.FechaAtencion =
            DateTime.UtcNow;

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Ok(new
        {
            mensaje =
                estado == "APROBADA"
                    ? "Solicitud de acceso aprobada correctamente."
                    : "Solicitud de acceso rechazada correctamente."
        });
    }

    // =========================================================
    // SOLICITUDES DE RECUPERACIÓN
    // =========================================================

    /// <summary>
    /// Obtiene las solicitudes de recuperación de contraseña
    /// incluyendo los datos del usuario asociado.
    /// </summary>
    [HttpGet("recuperacion")]
    [ProducesResponseType(
        typeof(List<SolicitudRecuperacionResponseDto>),
        StatusCodes.Status200OK)]
    public async Task<IActionResult>
        ObtenerSolicitudesRecuperacion(
            [FromQuery] string? estado,
            CancellationToken cancellationToken)
    {
        var consultaSolicitudes =
            _dbContext
                .SolicitudesRecuperacionPassword
                .AsNoTracking()
                .AsQueryable();

        // -----------------------------------------------------
        // FILTRO POR ESTADO
        // -----------------------------------------------------

        if (!string.IsNullOrWhiteSpace(estado))
        {
            string estadoNormalizado =
                estado.Trim().ToUpperInvariant();

            consultaSolicitudes =
                consultaSolicitudes.Where(
                    solicitud =>
                        solicitud.EstadoSolicitud ==
                        estadoNormalizado);
        }

        // -----------------------------------------------------
        // SOLICITUD + USUARIO
        // -----------------------------------------------------

        List<SolicitudRecuperacionResponseDto>
            solicitudes =
                await (
                    from solicitud
                        in consultaSolicitudes

                    join usuario
                        in _dbContext
                            .Usuarios
                            .AsNoTracking()
                        on solicitud.UsuarioId
                        equals (long?)usuario.Id
                        into usuarios

                    from usuario
                        in usuarios.DefaultIfEmpty()

                    orderby solicitud.FechaSolicitud
                        descending

                    select
                        new SolicitudRecuperacionResponseDto
                        {
                            Id =
                                solicitud.Id,

                            UsuarioId =
                                solicitud.UsuarioId,

                            Identificador =
                                solicitud.Identificador,

                            Correo =
                                solicitud.Correo,

                            // =====================================
                            // DATOS DEL USUARIO
                            // =====================================

                            Nombres =
                                usuario != null
                                    ? usuario.Nombres
                                    : string.Empty,

                            Apellidos =
                                usuario != null
                                    ? usuario.Apellidos
                                    : string.Empty,

                            NombreUsuario =
                                usuario != null
                                    ? usuario.NombreUsuario
                                    : string.Empty,

                            EstadoSolicitud =
                                solicitud.EstadoSolicitud,

                            FechaSolicitud =
                                solicitud.FechaSolicitud,

                            FechaAtencion =
                                solicitud.FechaAtencion
                        }
                )
                .ToListAsync(
                    cancellationToken);

        return Ok(solicitudes);
    }

    // =========================================================
    // CAMBIAR ESTADO DE RECUPERACIÓN
    // =========================================================

    [HttpPut("recuperacion/{id:long}/estado")]
    [ProducesResponseType(
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status400BadRequest)]
    [ProducesResponseType(
        StatusCodes.Status404NotFound)]
    public async Task<IActionResult>
        CambiarEstadoRecuperacion(
            long id,
            [FromBody]
            CambiarEstadoRecuperacionDto solicitud,
            CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return BadRequest(new
            {
                mensaje =
                    "El identificador de la solicitud "
                    + "no es válido."
            });
        }

        string estado =
            solicitud.Estado
                .Trim()
                .ToUpperInvariant();

        if (estado != "ATENDIDA" &&
            estado != "RECHAZADA")
        {
            return BadRequest(new
            {
                mensaje =
                    "El estado debe ser ATENDIDA "
                    + "o RECHAZADA."
            });
        }

        var entidad =
            await _dbContext
                .SolicitudesRecuperacionPassword
                .FirstOrDefaultAsync(
                    item => item.Id == id,
                    cancellationToken);

        if (entidad is null)
        {
            return NotFound(new
            {
                mensaje =
                    "No se encontró la solicitud "
                    + "de recuperación."
            });
        }

        if (entidad.EstadoSolicitud !=
            "PENDIENTE")
        {
            return BadRequest(new
            {
                mensaje =
                    "La solicitud ya fue atendida."
            });
        }

        entidad.EstadoSolicitud = estado;

        entidad.FechaAtencion =
            DateTime.UtcNow;

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Ok(new
        {
            mensaje =
                estado == "ATENDIDA"
                    ? "Solicitud de recuperación atendida correctamente."
                    : "Solicitud de recuperación rechazada correctamente."
        });
    }
}

// =============================================================
// DTO - SOLICITUD DE ACCESO
// =============================================================

public sealed class SolicitudAccesoResponseDto
{
    public long Id { get; set; }

    public string Nombres { get; set; } =
        string.Empty;

    public string Apellidos { get; set; } =
        string.Empty;

    public string Correo { get; set; } =
        string.Empty;

    public string Institucion { get; set; } =
        string.Empty;

    public string? Cargo { get; set; }

    public string? Motivo { get; set; }

    public string EstadoSolicitud { get; set; } =
        string.Empty;

    public DateTime FechaSolicitud { get; set; }

    public DateTime? FechaAtencion { get; set; }
}

// =============================================================
// DTO - RECUPERACIÓN
// =============================================================

public sealed class SolicitudRecuperacionResponseDto
{
    public long Id { get; set; }

    public long? UsuarioId { get; set; }

    public string Identificador { get; set; } =
        string.Empty;

    public string? Correo { get; set; }

    // =====================================================
    // DATOS DEL USUARIO
    // =====================================================

    public string Nombres { get; set; } =
        string.Empty;

    public string Apellidos { get; set; } =
        string.Empty;

    public string NombreUsuario { get; set; } =
        string.Empty;

    public string EstadoSolicitud { get; set; } =
        string.Empty;

    public DateTime FechaSolicitud { get; set; }

    public DateTime? FechaAtencion { get; set; }
}

// =============================================================
// DTO - ESTADO ACCESO
// =============================================================

public sealed class CambiarEstadoSolicitudAccesoDto
{
    public string Estado { get; set; } =
        string.Empty;
}

// =============================================================
// DTO - ESTADO RECUPERACIÓN
// =============================================================

public sealed class CambiarEstadoRecuperacionDto
{
    public string Estado { get; set; } =
        string.Empty;
}