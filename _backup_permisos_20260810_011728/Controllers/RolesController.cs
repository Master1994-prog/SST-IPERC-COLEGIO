using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SST.Domain.Security.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Api.Controllers;

/// <summary>
/// Gestiona los roles disponibles dentro del sistema SST/IPERC.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public sealed class RolesController : ControllerBase
{
    private readonly SSTDbContext _dbContext;

    public RolesController(SSTDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    /// <summary>
    /// Obtiene todos los roles activos.
    ///
    /// Permite filtrar por alcance global.
    ///
    /// Ejemplos:
    /// GET /api/Roles
    /// GET /api/Roles?esGlobal=true
    /// GET /api/Roles?esGlobal=false
    /// </summary>
    [HttpGet]
    [Authorize(Roles = "SUPER_ADMIN,ADMIN")]
    [ProducesResponseType(
        typeof(List<RolResponseDto>),
        StatusCodes.Status200OK)]
    public async Task<IActionResult> ObtenerTodos(
        [FromQuery] bool? esGlobal,
        CancellationToken cancellationToken)
    {
        IQueryable<Rol> consulta =
            _dbContext.Roles
                .AsNoTracking()
                .Where(rol =>
                    rol.Estado &&
                    rol.Activo);

        if (esGlobal.HasValue)
        {
            consulta = consulta.Where(
                rol => rol.EsGlobal == esGlobal.Value);
        }

        List<RolResponseDto> roles =
            await consulta
                .OrderBy(rol => rol.Nombre)
                .Select(rol => new RolResponseDto
                {
                    Id = rol.Id,
                    Codigo = rol.Codigo,
                    Nombre = rol.Nombre,
                    Descripcion = rol.Descripcion,
                    Activo = rol.Activo,
                    EsGlobal = rol.EsGlobal,
                    FechaRegistro = rol.FechaRegistro,
                    FechaActualizacion =
                        rol.FechaActualizacion
                })
                .ToListAsync(cancellationToken);

        return Ok(roles);
    }

    /// <summary>
    /// Obtiene un rol mediante su identificador.
    /// </summary>
    [HttpGet("{id:long}")]
    [Authorize(Roles = "SUPER_ADMIN,ADMIN")]
    [ProducesResponseType(
        typeof(RolResponseDto),
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ObtenerPorId(
        long id,
        CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return BadRequest(new
            {
                mensaje =
                    "El identificador del rol no es válido."
            });
        }

        RolResponseDto? rol =
            await _dbContext.Roles
                .AsNoTracking()
                .Where(item =>
                    item.Id == id &&
                    item.Estado)
                .Select(item => new RolResponseDto
                {
                    Id = item.Id,
                    Codigo = item.Codigo,
                    Nombre = item.Nombre,
                    Descripcion = item.Descripcion,
                    Activo = item.Activo,
                    EsGlobal = item.EsGlobal,
                    FechaRegistro = item.FechaRegistro,
                    FechaActualizacion =
                        item.FechaActualizacion
                })
                .FirstOrDefaultAsync(
                    cancellationToken);

        if (rol is null)
        {
            return NotFound(new
            {
                mensaje =
                    "No se encontró el rol solicitado."
            });
        }

        return Ok(rol);
    }

    /// <summary>
    /// Registra un nuevo rol.
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "SUPER_ADMIN")]
    [ProducesResponseType(
        typeof(RolResponseDto),
        StatusCodes.Status201Created)]
    [ProducesResponseType(
        StatusCodes.Status400BadRequest)]
    [ProducesResponseType(
        StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Crear(
        [FromBody] CrearRolDto solicitud,
        CancellationToken cancellationToken)
    {
        string codigo =
            solicitud.Codigo.Trim().ToUpperInvariant();

        string nombre = solicitud.Nombre.Trim();

        string? descripcion =
            LimpiarTextoOpcional(
                solicitud.Descripcion);

        bool codigoDuplicado =
            await _dbContext.Roles
                .AsNoTracking()
                .AnyAsync(
                    rol =>
                        rol.Estado &&
                        rol.Codigo.ToUpper() == codigo,
                    cancellationToken);

        if (codigoDuplicado)
        {
            return Conflict(new
            {
                mensaje =
                    "Ya existe un rol con el código indicado."
            });
        }

        bool nombreDuplicado =
            await _dbContext.Roles
                .AsNoTracking()
                .AnyAsync(
                    rol =>
                        rol.Estado &&
                        rol.Nombre.ToLower() ==
                        nombre.ToLower(),
                    cancellationToken);

        if (nombreDuplicado)
        {
            return Conflict(new
            {
                mensaje =
                    "Ya existe un rol con el nombre indicado."
            });
        }

        var rol = new Rol
        {
            Codigo = codigo,
            Nombre = nombre,
            Descripcion = descripcion,
            Activo = true,
            EsGlobal = solicitud.EsGlobal,
            Estado = true,
            FechaRegistro = DateTime.UtcNow,
            UsuarioRegistroId =
                ObtenerUsuarioId(
                    solicitud.UsuarioRegistroId)
        };

        _dbContext.Roles.Add(rol);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        var respuesta = new RolResponseDto
        {
            Id = rol.Id,
            Codigo = rol.Codigo,
            Nombre = rol.Nombre,
            Descripcion = rol.Descripcion,
            Activo = rol.Activo,
            EsGlobal = rol.EsGlobal,
            FechaRegistro = rol.FechaRegistro,
            FechaActualizacion =
                rol.FechaActualizacion
        };

        return CreatedAtAction(
            nameof(ObtenerPorId),
            new { id = rol.Id },
            respuesta);
    }

    /// <summary>
    /// Actualiza los datos de un rol existente.
    /// </summary>
    [HttpPut("{id:long}")]
    [Authorize(Roles = "SUPER_ADMIN")]
    [ProducesResponseType(
        typeof(RolResponseDto),
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status400BadRequest)]
    [ProducesResponseType(
        StatusCodes.Status404NotFound)]
    [ProducesResponseType(
        StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Actualizar(
        long id,
        [FromBody] ActualizarRolDto solicitud,
        CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return BadRequest(new
            {
                mensaje =
                    "El identificador del rol no es válido."
            });
        }

        Rol? rol =
            await _dbContext.Roles
                .FirstOrDefaultAsync(
                    item =>
                        item.Id == id &&
                        item.Estado,
                    cancellationToken);

        if (rol is null)
        {
            return NotFound(new
            {
                mensaje =
                    "No se encontró el rol que se desea actualizar."
            });
        }

        string codigo =
            solicitud.Codigo.Trim().ToUpperInvariant();

        string nombre = solicitud.Nombre.Trim();

        string? descripcion =
            LimpiarTextoOpcional(
                solicitud.Descripcion);

        bool codigoDuplicado =
            await _dbContext.Roles
                .AsNoTracking()
                .AnyAsync(
                    item =>
                        item.Id != id &&
                        item.Estado &&
                        item.Codigo.ToUpper() == codigo,
                    cancellationToken);

        if (codigoDuplicado)
        {
            return Conflict(new
            {
                mensaje =
                    "Ya existe otro rol con el código indicado."
            });
        }

        bool nombreDuplicado =
            await _dbContext.Roles
                .AsNoTracking()
                .AnyAsync(
                    item =>
                        item.Id != id &&
                        item.Estado &&
                        item.Nombre.ToLower() ==
                        nombre.ToLower(),
                    cancellationToken);

        if (nombreDuplicado)
        {
            return Conflict(new
            {
                mensaje =
                    "Ya existe otro rol con el nombre indicado."
            });
        }

        rol.Codigo = codigo;
        rol.Nombre = nombre;
        rol.Descripcion = descripcion;
        rol.Activo = solicitud.Activo;
        rol.EsGlobal = solicitud.EsGlobal;
        rol.FechaActualizacion = DateTime.UtcNow;
        rol.UsuarioActualizacionId =
            ObtenerUsuarioId(
                solicitud.UsuarioActualizacionId);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        var respuesta = new RolResponseDto
        {
            Id = rol.Id,
            Codigo = rol.Codigo,
            Nombre = rol.Nombre,
            Descripcion = rol.Descripcion,
            Activo = rol.Activo,
            EsGlobal = rol.EsGlobal,
            FechaRegistro = rol.FechaRegistro,
            FechaActualizacion =
                rol.FechaActualizacion
        };

        return Ok(respuesta);
    }

    /// <summary>
    /// Realiza la eliminación lógica de un rol.
    /// </summary>
    [HttpDelete("{id:long}")]
    [Authorize(Roles = "SUPER_ADMIN")]
    [ProducesResponseType(
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status404NotFound)]
    [ProducesResponseType(
        StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Eliminar(
        long id,
        [FromQuery] long? usuarioId,
        CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return BadRequest(new
            {
                mensaje =
                    "El identificador del rol no es válido."
            });
        }

        Rol? rol =
            await _dbContext.Roles
                .FirstOrDefaultAsync(
                    item =>
                        item.Id == id &&
                        item.Estado,
                    cancellationToken);

        if (rol is null)
        {
            return NotFound(new
            {
                mensaje =
                    "No se encontró el rol que se desea eliminar."
            });
        }

        bool tieneUsuariosAsignados =
            await _dbContext.UsuariosRoles
                .AsNoTracking()
                .AnyAsync(
                    relacion =>
                        relacion.RolId == id &&
                        relacion.Estado &&
                        relacion.Activo,
                    cancellationToken);

        if (tieneUsuariosAsignados)
        {
            return Conflict(new
            {
                mensaje =
                    "No se puede eliminar el rol porque está asignado a uno o más usuarios."
            });
        }

        rol.Activo = false;
        rol.Estado = false;
        rol.FechaActualizacion = DateTime.UtcNow;
        rol.UsuarioActualizacionId =
            ObtenerUsuarioId(usuarioId);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Ok(new
        {
            mensaje =
                "Rol eliminado correctamente."
        });
    }

    /// <summary>
    /// Activa o desactiva un rol sin eliminarlo.
    /// </summary>
    [HttpPatch("{id:long}/estado")]
    [Authorize(Roles = "SUPER_ADMIN")]
    [ProducesResponseType(
        typeof(RolResponseDto),
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status404NotFound)]
    public async Task<IActionResult> CambiarEstado(
        long id,
        [FromBody] CambiarEstadoRolDto solicitud,
        CancellationToken cancellationToken)
    {
        Rol? rol =
            await _dbContext.Roles
                .FirstOrDefaultAsync(
                    item =>
                        item.Id == id &&
                        item.Estado,
                    cancellationToken);

        if (rol is null)
        {
            return NotFound(new
            {
                mensaje =
                    "No se encontró el rol solicitado."
            });
        }

        rol.Activo = solicitud.Activo;
        rol.FechaActualizacion = DateTime.UtcNow;
        rol.UsuarioActualizacionId =
            ObtenerUsuarioId(
                solicitud.UsuarioActualizacionId);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Ok(new RolResponseDto
        {
            Id = rol.Id,
            Codigo = rol.Codigo,
            Nombre = rol.Nombre,
            Descripcion = rol.Descripcion,
            Activo = rol.Activo,
            EsGlobal = rol.EsGlobal,
            FechaRegistro = rol.FechaRegistro,
            FechaActualizacion =
                rol.FechaActualizacion
        });
    }

    private static long ObtenerUsuarioId(
        long? usuarioId)
    {
        return usuarioId.HasValue &&
               usuarioId.Value > 0
            ? usuarioId.Value
            : 1;
    }

    private static string? LimpiarTextoOpcional(
        string? texto)
    {
        return string.IsNullOrWhiteSpace(texto)
            ? null
            : texto.Trim();
    }
}

/// <summary>
/// Datos requeridos para registrar un rol.
/// </summary>
public sealed class CrearRolDto
{
    [Required(
        ErrorMessage =
            "El código del rol es obligatorio.")]
    [StringLength(
        50,
        MinimumLength = 2,
        ErrorMessage =
            "El código debe tener entre 2 y 50 caracteres.")]
    public string Codigo { get; set; } =
        string.Empty;

    [Required(
        ErrorMessage =
            "El nombre del rol es obligatorio.")]
    [StringLength(
        100,
        MinimumLength = 2,
        ErrorMessage =
            "El nombre debe tener entre 2 y 100 caracteres.")]
    public string Nombre { get; set; } =
        string.Empty;

    [StringLength(
        300,
        ErrorMessage =
            "La descripción no puede superar 300 caracteres.")]
    public string? Descripcion { get; set; }

    public bool EsGlobal { get; set; }

    public long? UsuarioRegistroId { get; set; }
}

/// <summary>
/// Datos requeridos para actualizar un rol.
/// </summary>
public sealed class ActualizarRolDto
{
    [Required(
        ErrorMessage =
            "El código del rol es obligatorio.")]
    [StringLength(
        50,
        MinimumLength = 2,
        ErrorMessage =
            "El código debe tener entre 2 y 50 caracteres.")]
    public string Codigo { get; set; } =
        string.Empty;

    [Required(
        ErrorMessage =
            "El nombre del rol es obligatorio.")]
    [StringLength(
        100,
        MinimumLength = 2,
        ErrorMessage =
            "El nombre debe tener entre 2 y 100 caracteres.")]
    public string Nombre { get; set; } =
        string.Empty;

    [StringLength(
        300,
        ErrorMessage =
            "La descripción no puede superar 300 caracteres.")]
    public string? Descripcion { get; set; }

    public bool Activo { get; set; } = true;

    public bool EsGlobal { get; set; }

    public long? UsuarioActualizacionId { get; set; }
}

/// <summary>
/// Datos requeridos para activar o desactivar un rol.
/// </summary>
public sealed class CambiarEstadoRolDto
{
    public bool Activo { get; set; }

    public long? UsuarioActualizacionId { get; set; }
}

/// <summary>
/// Información del rol enviada al cliente móvil.
/// </summary>
public sealed class RolResponseDto
{
    public long Id { get; set; }

    public string Codigo { get; set; } =
        string.Empty;

    public string Nombre { get; set; } =
        string.Empty;

    public string? Descripcion { get; set; }

    public bool Activo { get; set; }

    public bool EsGlobal { get; set; }

    public DateTime FechaRegistro { get; set; }

    public DateTime? FechaActualizacion { get; set; }
}