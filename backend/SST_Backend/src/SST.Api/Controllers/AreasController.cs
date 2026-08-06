using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SST.Domain.Organization.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Api.Controllers;

/// <summary>
/// Gestiona las áreas pertenecientes a las instituciones.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public sealed class AreasController : ControllerBase
{
    private readonly SSTDbContext _dbContext;

    public AreasController(SSTDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    /// <summary>
    /// Obtiene las áreas activas.
    /// Puede filtrarse por institución.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> ObtenerTodas(
        [FromQuery] long? institucionId,
        CancellationToken cancellationToken)
    {
        IQueryable<Area> consulta = _dbContext.Areas
            .AsNoTracking()
            .Where(x => x.Estado && x.Activo);

        if (institucionId.HasValue && institucionId.Value > 0)
        {
            consulta = consulta.Where(
                x => x.InstitucionId == institucionId.Value);
        }

        var areas = await consulta
            .OrderBy(x => x.Nombre)
            .Select(x => new AreaResponseDto
            {
                Id = x.Id,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                Activo = x.Activo,
                InstitucionId = x.InstitucionId,
                InstitucionNombre = x.Institucion.Nombre,
                FechaRegistro = x.FechaRegistro,
                FechaActualizacion = x.FechaActualizacion
            })
            .ToListAsync(cancellationToken);

        return Ok(areas);
    }

    /// <summary>
    /// Obtiene un área mediante su identificador.
    /// </summary>
    [HttpGet("{id:long}")]
    public async Task<IActionResult> ObtenerPorId(
        long id,
        CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return BadRequest(new
            {
                mensaje = "El identificador del área no es válido."
            });
        }

        AreaResponseDto? area = await _dbContext.Areas
            .AsNoTracking()
            .Where(x => x.Id == id && x.Estado)
            .Select(x => new AreaResponseDto
            {
                Id = x.Id,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                Activo = x.Activo,
                InstitucionId = x.InstitucionId,
                InstitucionNombre = x.Institucion.Nombre,
                FechaRegistro = x.FechaRegistro,
                FechaActualizacion = x.FechaActualizacion
            })
            .FirstOrDefaultAsync(cancellationToken);

        if (area is null)
        {
            return NotFound(new
            {
                mensaje = "No se encontró el área solicitada."
            });
        }

        return Ok(area);
    }

    /// <summary>
    /// Registra una nueva área.
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> Crear(
        [FromBody] CrearAreaDto solicitud,
        CancellationToken cancellationToken)
    {
        string nombre = solicitud.Nombre.Trim();
        string? descripcion = LimpiarTextoOpcional(
            solicitud.Descripcion);

        bool institucionExiste = await _dbContext.Instituciones
            .AsNoTracking()
            .AnyAsync(
                x => x.Id == solicitud.InstitucionId &&
                     x.Estado,
                cancellationToken);

        if (!institucionExiste)
        {
            return BadRequest(new
            {
                mensaje = "La institución seleccionada no existe o está inactiva."
            });
        }

        bool nombreDuplicado = await _dbContext.Areas
            .AsNoTracking()
            .AnyAsync(
                x => x.InstitucionId == solicitud.InstitucionId &&
                     x.Estado &&
                     x.Nombre.ToLower() == nombre.ToLower(),
                cancellationToken);

        if (nombreDuplicado)
        {
            return Conflict(new
            {
                mensaje = "Ya existe un área con ese nombre en la institución."
            });
        }

        var area = new Area
        {
            Nombre = nombre,
            Descripcion = descripcion,
            InstitucionId = solicitud.InstitucionId,
            Activo = true,
            Estado = true,
            FechaRegistro = DateTime.UtcNow,
            UsuarioRegistroId = ObtenerUsuarioId(
                solicitud.UsuarioRegistroId),
            EsGlobal = false,
            ColegioId = solicitud.ColegioId
        };

        _dbContext.Areas.Add(area);
        await _dbContext.SaveChangesAsync(cancellationToken);

        AreaResponseDto? resultado = await _dbContext.Areas
            .AsNoTracking()
            .Where(x => x.Id == area.Id)
            .Select(x => new AreaResponseDto
            {
                Id = x.Id,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                Activo = x.Activo,
                InstitucionId = x.InstitucionId,
                InstitucionNombre = x.Institucion.Nombre,
                FechaRegistro = x.FechaRegistro,
                FechaActualizacion = x.FechaActualizacion
            })
            .FirstOrDefaultAsync(cancellationToken);

        return CreatedAtAction(
            nameof(ObtenerPorId),
            new { id = area.Id },
            resultado);
    }

    /// <summary>
    /// Actualiza un área existente.
    /// </summary>
    [HttpPut("{id:long}")]
    public async Task<IActionResult> Actualizar(
        long id,
        [FromBody] ActualizarAreaDto solicitud,
        CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return BadRequest(new
            {
                mensaje = "El identificador del área no es válido."
            });
        }

        Area? area = await _dbContext.Areas
            .FirstOrDefaultAsync(
                x => x.Id == id && x.Estado,
                cancellationToken);

        if (area is null)
        {
            return NotFound(new
            {
                mensaje = "No se encontró el área que se desea actualizar."
            });
        }

        string nombre = solicitud.Nombre.Trim();
        string? descripcion = LimpiarTextoOpcional(
            solicitud.Descripcion);

        bool institucionExiste = await _dbContext.Instituciones
            .AsNoTracking()
            .AnyAsync(
                x => x.Id == solicitud.InstitucionId &&
                     x.Estado,
                cancellationToken);

        if (!institucionExiste)
        {
            return BadRequest(new
            {
                mensaje = "La institución seleccionada no existe o está inactiva."
            });
        }

        bool nombreDuplicado = await _dbContext.Areas
            .AsNoTracking()
            .AnyAsync(
                x => x.Id != id &&
                     x.InstitucionId == solicitud.InstitucionId &&
                     x.Estado &&
                     x.Nombre.ToLower() == nombre.ToLower(),
                cancellationToken);

        if (nombreDuplicado)
        {
            return Conflict(new
            {
                mensaje = "Ya existe otra área con ese nombre en la institución."
            });
        }

        area.Nombre = nombre;
        area.Descripcion = descripcion;
        area.InstitucionId = solicitud.InstitucionId;
        area.Activo = solicitud.Activo;
        area.FechaActualizacion = DateTime.UtcNow;
        area.UsuarioActualizacionId = ObtenerUsuarioId(
            solicitud.UsuarioActualizacionId);

        await _dbContext.SaveChangesAsync(cancellationToken);

        AreaResponseDto? resultado = await _dbContext.Areas
            .AsNoTracking()
            .Where(x => x.Id == area.Id)
            .Select(x => new AreaResponseDto
            {
                Id = x.Id,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                Activo = x.Activo,
                InstitucionId = x.InstitucionId,
                InstitucionNombre = x.Institucion.Nombre,
                FechaRegistro = x.FechaRegistro,
                FechaActualizacion = x.FechaActualizacion
            })
            .FirstOrDefaultAsync(cancellationToken);

        return Ok(resultado);
    }

    /// <summary>
    /// Realiza la eliminación lógica de un área.
    /// </summary>
    [HttpDelete("{id:long}")]
    public async Task<IActionResult> Eliminar(
        long id,
        [FromQuery] long? usuarioId,
        CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return BadRequest(new
            {
                mensaje = "El identificador del área no es válido."
            });
        }

        Area? area = await _dbContext.Areas
            .FirstOrDefaultAsync(
                x => x.Id == id && x.Estado,
                cancellationToken);

        if (area is null)
        {
            return NotFound(new
            {
                mensaje = "No se encontró el área que se desea eliminar."
            });
        }

        bool tieneProcesos = await _dbContext.Procesos
            .AsNoTracking()
            .AnyAsync(
                x => x.AreaId == id && x.Estado,
                cancellationToken);

        bool tienePuestos = await _dbContext.PuestosTrabajo
            .AsNoTracking()
            .AnyAsync(
                x => x.AreaId == id && x.Estado,
                cancellationToken);

        if (tieneProcesos || tienePuestos)
        {
            return Conflict(new
            {
                mensaje =
                    "No se puede eliminar el área porque tiene procesos " +
                    "o puestos de trabajo relacionados."
            });
        }

        area.Activo = false;
        area.Estado = false;
        area.FechaActualizacion = DateTime.UtcNow;
        area.UsuarioActualizacionId = ObtenerUsuarioId(usuarioId);

        await _dbContext.SaveChangesAsync(cancellationToken);

        return Ok(new
        {
            mensaje = "Área eliminada correctamente."
        });
    }

    private static long ObtenerUsuarioId(long? usuarioId)
    {
        // Valor provisional hasta obtener el usuario desde el token JWT.
        return usuarioId.HasValue && usuarioId.Value > 0
            ? usuarioId.Value
            : 1;
    }

    private static string? LimpiarTextoOpcional(string? texto)
    {
        if (string.IsNullOrWhiteSpace(texto))
        {
            return null;
        }

        return texto.Trim();
    }
}

/// <summary>
/// Datos para registrar una nueva área.
/// </summary>
public sealed class CrearAreaDto
{
    [Required(ErrorMessage = "El nombre del área es obligatorio.")]
    [StringLength(
        150,
        MinimumLength = 2,
        ErrorMessage = "El nombre debe tener entre 2 y 150 caracteres.")]
    public string Nombre { get; set; } = string.Empty;

    [StringLength(
        500,
        ErrorMessage = "La descripción no puede superar 500 caracteres.")]
    public string? Descripcion { get; set; }

    [Range(
        1,
        long.MaxValue,
        ErrorMessage = "Debe seleccionar una institución válida.")]
    public long InstitucionId { get; set; }

    public long? UsuarioRegistroId { get; set; }

    public long? ColegioId { get; set; }
}

/// <summary>
/// Datos para modificar un área.
/// </summary>
public sealed class ActualizarAreaDto
{
    [Required(ErrorMessage = "El nombre del área es obligatorio.")]
    [StringLength(
        150,
        MinimumLength = 2,
        ErrorMessage = "El nombre debe tener entre 2 y 150 caracteres.")]
    public string Nombre { get; set; } = string.Empty;

    [StringLength(
        500,
        ErrorMessage = "La descripción no puede superar 500 caracteres.")]
    public string? Descripcion { get; set; }

    [Range(
        1,
        long.MaxValue,
        ErrorMessage = "Debe seleccionar una institución válida.")]
    public long InstitucionId { get; set; }

    public bool Activo { get; set; } = true;

    public long? UsuarioActualizacionId { get; set; }
}

/// <summary>
/// Información de un área enviada al cliente.
/// </summary>
public sealed class AreaResponseDto
{
    public long Id { get; set; }

    public string Nombre { get; set; } = string.Empty;

    public string? Descripcion { get; set; }

    public bool Activo { get; set; }

    public long InstitucionId { get; set; }

    public string InstitucionNombre { get; set; } = string.Empty;

    public DateTime FechaRegistro { get; set; }

    public DateTime? FechaActualizacion { get; set; }
}