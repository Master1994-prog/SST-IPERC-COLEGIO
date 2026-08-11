using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SST.Domain.Organization.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Api.Controllers;

/// <summary>
/// Gestiona los procesos pertenecientes a las áreas.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public sealed class ProcesosController : ControllerBase
{
    private readonly SSTDbContext _dbContext;

    public ProcesosController(SSTDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    /// <summary>
    /// Obtiene los procesos activos.
    /// Permite filtrar por área.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> ObtenerTodos(
        [FromQuery] long? areaId,
        CancellationToken cancellationToken)
    {
        IQueryable<Proceso> consulta = _dbContext.Procesos
            .AsNoTracking()
            .Where(x => x.Estado && x.Activo);

        if (areaId.HasValue && areaId.Value > 0)
        {
            consulta = consulta.Where(
                x => x.AreaId == areaId.Value);
        }

        List<ProcesoResponseDto> procesos = await consulta
            .OrderBy(x => x.Nombre)
            .Select(x => new ProcesoResponseDto
            {
                Id = x.Id,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                Activo = x.Activo,
                AreaId = x.AreaId,
                AreaNombre = x.Area.Nombre,
                FechaRegistro = x.FechaRegistro,
                FechaActualizacion = x.FechaActualizacion
            })
            .ToListAsync(cancellationToken);

        return Ok(procesos);
    }

    /// <summary>
    /// Obtiene un proceso mediante su identificador.
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
                mensaje = "El identificador del proceso no es válido."
            });
        }

        ProcesoResponseDto? proceso = await _dbContext.Procesos
            .AsNoTracking()
            .Where(x => x.Id == id && x.Estado)
            .Select(x => new ProcesoResponseDto
            {
                Id = x.Id,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                Activo = x.Activo,
                AreaId = x.AreaId,
                AreaNombre = x.Area.Nombre,
                FechaRegistro = x.FechaRegistro,
                FechaActualizacion = x.FechaActualizacion
            })
            .FirstOrDefaultAsync(cancellationToken);

        if (proceso is null)
        {
            return NotFound(new
            {
                mensaje = "No se encontró el proceso solicitado."
            });
        }

        return Ok(proceso);
    }

    /// <summary>
    /// Registra un nuevo proceso.
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> Crear(
        [FromBody] CrearProcesoDto solicitud,
        CancellationToken cancellationToken)
    {
        string nombre = solicitud.Nombre.Trim();
        string? descripcion = LimpiarTextoOpcional(
            solicitud.Descripcion);

        bool areaExiste = await _dbContext.Areas
            .AsNoTracking()
            .AnyAsync(
                x => x.Id == solicitud.AreaId &&
                     x.Estado &&
                     x.Activo,
                cancellationToken);

        if (!areaExiste)
        {
            return BadRequest(new
            {
                mensaje = "El área seleccionada no existe o está inactiva."
            });
        }

        bool nombreDuplicado = await _dbContext.Procesos
            .AsNoTracking()
            .AnyAsync(
                x => x.AreaId == solicitud.AreaId &&
                     x.Estado &&
                     x.Nombre.ToLower() == nombre.ToLower(),
                cancellationToken);

        if (nombreDuplicado)
        {
            return Conflict(new
            {
                mensaje = "Ya existe un proceso con ese nombre en el área."
            });
        }

        var proceso = new Proceso
        {
            Nombre = nombre,
            Descripcion = descripcion,
            AreaId = solicitud.AreaId,
            Activo = true,
            Estado = true,
            FechaRegistro = DateTime.UtcNow,
            UsuarioRegistroId = ObtenerUsuarioId(
                solicitud.UsuarioRegistroId),
            EsGlobal = false,
            ColegioId = solicitud.ColegioId
        };

        _dbContext.Procesos.Add(proceso);
        await _dbContext.SaveChangesAsync(cancellationToken);

        ProcesoResponseDto? resultado = await _dbContext.Procesos
            .AsNoTracking()
            .Where(x => x.Id == proceso.Id)
            .Select(x => new ProcesoResponseDto
            {
                Id = x.Id,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                Activo = x.Activo,
                AreaId = x.AreaId,
                AreaNombre = x.Area.Nombre,
                FechaRegistro = x.FechaRegistro,
                FechaActualizacion = x.FechaActualizacion
            })
            .FirstOrDefaultAsync(cancellationToken);

        return CreatedAtAction(
            nameof(ObtenerPorId),
            new { id = proceso.Id },
            resultado);
    }

    /// <summary>
    /// Actualiza un proceso existente.
    /// </summary>
    [HttpPut("{id:long}")]
    public async Task<IActionResult> Actualizar(
        long id,
        [FromBody] ActualizarProcesoDto solicitud,
        CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return BadRequest(new
            {
                mensaje = "El identificador del proceso no es válido."
            });
        }

        Proceso? proceso = await _dbContext.Procesos
            .FirstOrDefaultAsync(
                x => x.Id == id && x.Estado,
                cancellationToken);

        if (proceso is null)
        {
            return NotFound(new
            {
                mensaje = "No se encontró el proceso que se desea actualizar."
            });
        }

        string nombre = solicitud.Nombre.Trim();
        string? descripcion = LimpiarTextoOpcional(
            solicitud.Descripcion);

        bool areaExiste = await _dbContext.Areas
            .AsNoTracking()
            .AnyAsync(
                x => x.Id == solicitud.AreaId &&
                     x.Estado &&
                     x.Activo,
                cancellationToken);

        if (!areaExiste)
        {
            return BadRequest(new
            {
                mensaje = "El área seleccionada no existe o está inactiva."
            });
        }

        bool nombreDuplicado = await _dbContext.Procesos
            .AsNoTracking()
            .AnyAsync(
                x => x.Id != id &&
                     x.AreaId == solicitud.AreaId &&
                     x.Estado &&
                     x.Nombre.ToLower() == nombre.ToLower(),
                cancellationToken);

        if (nombreDuplicado)
        {
            return Conflict(new
            {
                mensaje = "Ya existe otro proceso con ese nombre en el área."
            });
        }

        proceso.Nombre = nombre;
        proceso.Descripcion = descripcion;
        proceso.AreaId = solicitud.AreaId;
        proceso.Activo = solicitud.Activo;
        proceso.FechaActualizacion = DateTime.UtcNow;
        proceso.UsuarioActualizacionId = ObtenerUsuarioId(
            solicitud.UsuarioActualizacionId);

        await _dbContext.SaveChangesAsync(cancellationToken);

        ProcesoResponseDto? resultado = await _dbContext.Procesos
            .AsNoTracking()
            .Where(x => x.Id == proceso.Id)
            .Select(x => new ProcesoResponseDto
            {
                Id = x.Id,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                Activo = x.Activo,
                AreaId = x.AreaId,
                AreaNombre = x.Area.Nombre,
                FechaRegistro = x.FechaRegistro,
                FechaActualizacion = x.FechaActualizacion
            })
            .FirstOrDefaultAsync(cancellationToken);

        return Ok(resultado);
    }

    /// <summary>
    /// Realiza la eliminación lógica de un proceso.
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
                mensaje = "El identificador del proceso no es válido."
            });
        }

        Proceso? proceso = await _dbContext.Procesos
            .FirstOrDefaultAsync(
                x => x.Id == id && x.Estado,
                cancellationToken);

        if (proceso is null)
        {
            return NotFound(new
            {
                mensaje = "No se encontró el proceso que se desea eliminar."
            });
        }

        bool tieneActividades = await _dbContext.Actividades
            .AsNoTracking()
            .AnyAsync(
                x => x.ProcesoId == id && x.Estado,
                cancellationToken);

        if (tieneActividades)
        {
            return Conflict(new
            {
                mensaje =
                    "No se puede eliminar el proceso porque tiene " +
                    "actividades relacionadas."
            });
        }

        proceso.Activo = false;
        proceso.Estado = false;
        proceso.FechaActualizacion = DateTime.UtcNow;
        proceso.UsuarioActualizacionId = ObtenerUsuarioId(
            usuarioId);

        await _dbContext.SaveChangesAsync(cancellationToken);

        return Ok(new
        {
            mensaje = "Proceso eliminado correctamente."
        });
    }

    private static long ObtenerUsuarioId(long? usuarioId)
    {
        // Valor temporal hasta obtener el usuario desde el token JWT.
        return usuarioId.HasValue && usuarioId.Value > 0
            ? usuarioId.Value
            : 1;
    }

    private static string? LimpiarTextoOpcional(string? texto)
    {
        return string.IsNullOrWhiteSpace(texto)
            ? null
            : texto.Trim();
    }
}

/// <summary>
/// Datos necesarios para registrar un proceso.
/// </summary>
public sealed class CrearProcesoDto
{
    [Required(ErrorMessage = "El nombre del proceso es obligatorio.")]
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
        ErrorMessage = "Debe seleccionar un área válida.")]
    public long AreaId { get; set; }

    public long? UsuarioRegistroId { get; set; }

    public long? ColegioId { get; set; }
}

/// <summary>
/// Datos necesarios para actualizar un proceso.
/// </summary>
public sealed class ActualizarProcesoDto
{
    [Required(ErrorMessage = "El nombre del proceso es obligatorio.")]
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
        ErrorMessage = "Debe seleccionar un área válida.")]
    public long AreaId { get; set; }

    public bool Activo { get; set; } = true;

    public long? UsuarioActualizacionId { get; set; }
}

/// <summary>
/// Información de un proceso enviada al cliente móvil.
/// </summary>
public sealed class ProcesoResponseDto
{
    public long Id { get; set; }

    public string Nombre { get; set; } = string.Empty;

    public string? Descripcion { get; set; }

    public bool Activo { get; set; }

    public long AreaId { get; set; }

    public string AreaNombre { get; set; } = string.Empty;

    public DateTime FechaRegistro { get; set; }

    public DateTime? FechaActualizacion { get; set; }
}
