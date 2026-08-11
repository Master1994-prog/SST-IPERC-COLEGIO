using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SST.Domain.Organization.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Api.Controllers;

/// <summary>
/// Gestiona los puestos de trabajo pertenecientes a las áreas.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public sealed class PuestosTrabajoController : ControllerBase
{
    private readonly SSTDbContext _dbContext;

    public PuestosTrabajoController(
        SSTDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    /// <summary>
    /// Obtiene todos los puestos de trabajo activos.
    /// Permite filtrar por área.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> ObtenerTodos(
        [FromQuery] long? areaId,
        CancellationToken cancellationToken)
    {
        IQueryable<PuestoTrabajo> consulta =
            _dbContext.PuestosTrabajo
                .AsNoTracking()
                .Where(x => x.Estado && x.Activo);

        if (areaId.HasValue && areaId.Value > 0)
        {
            consulta = consulta.Where(
                x => x.AreaId == areaId.Value);
        }

        List<PuestoTrabajoResponseDto> puestos =
            await consulta
                .OrderBy(x => x.Nombre)
                .Select(x => new PuestoTrabajoResponseDto
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

        return Ok(puestos);
    }

    /// <summary>
    /// Obtiene un puesto de trabajo mediante su identificador.
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
                mensaje =
                    "El identificador del puesto de trabajo no es válido."
            });
        }

        PuestoTrabajoResponseDto? puesto =
            await _dbContext.PuestosTrabajo
                .AsNoTracking()
                .Where(x => x.Id == id && x.Estado)
                .Select(x => new PuestoTrabajoResponseDto
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

        if (puesto is null)
        {
            return NotFound(new
            {
                mensaje =
                    "No se encontró el puesto de trabajo solicitado."
            });
        }

        return Ok(puesto);
    }

    /// <summary>
    /// Registra un nuevo puesto de trabajo.
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> Crear(
        [FromBody] CrearPuestoTrabajoDto solicitud,
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
                mensaje =
                    "El área seleccionada no existe o está inactiva."
            });
        }

        bool nombreDuplicado =
            await _dbContext.PuestosTrabajo
                .AsNoTracking()
                .AnyAsync(
                    x => x.AreaId == solicitud.AreaId &&
                         x.Estado &&
                         x.Nombre.ToLower() ==
                         nombre.ToLower(),
                    cancellationToken);

        if (nombreDuplicado)
        {
            return Conflict(new
            {
                mensaje =
                    "Ya existe un puesto de trabajo con ese nombre en el área."
            });
        }

        var puesto = new PuestoTrabajo
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

        _dbContext.PuestosTrabajo.Add(puesto);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        PuestoTrabajoResponseDto? resultado =
            await _dbContext.PuestosTrabajo
                .AsNoTracking()
                .Where(x => x.Id == puesto.Id)
                .Select(x => new PuestoTrabajoResponseDto
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
            new { id = puesto.Id },
            resultado);
    }

    /// <summary>
    /// Actualiza un puesto de trabajo existente.
    /// </summary>
    [HttpPut("{id:long}")]
    public async Task<IActionResult> Actualizar(
        long id,
        [FromBody] ActualizarPuestoTrabajoDto solicitud,
        CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return BadRequest(new
            {
                mensaje =
                    "El identificador del puesto de trabajo no es válido."
            });
        }

        PuestoTrabajo? puesto =
            await _dbContext.PuestosTrabajo
                .FirstOrDefaultAsync(
                    x => x.Id == id && x.Estado,
                    cancellationToken);

        if (puesto is null)
        {
            return NotFound(new
            {
                mensaje =
                    "No se encontró el puesto de trabajo que se desea actualizar."
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
                mensaje =
                    "El área seleccionada no existe o está inactiva."
            });
        }

        bool nombreDuplicado =
            await _dbContext.PuestosTrabajo
                .AsNoTracking()
                .AnyAsync(
                    x => x.Id != id &&
                         x.AreaId == solicitud.AreaId &&
                         x.Estado &&
                         x.Nombre.ToLower() ==
                         nombre.ToLower(),
                    cancellationToken);

        if (nombreDuplicado)
        {
            return Conflict(new
            {
                mensaje =
                    "Ya existe otro puesto de trabajo con ese nombre en el área."
            });
        }

        puesto.Nombre = nombre;
        puesto.Descripcion = descripcion;
        puesto.AreaId = solicitud.AreaId;
        puesto.Activo = solicitud.Activo;
        puesto.FechaActualizacion = DateTime.UtcNow;
        puesto.UsuarioActualizacionId =
            ObtenerUsuarioId(
                solicitud.UsuarioActualizacionId);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        PuestoTrabajoResponseDto? resultado =
            await _dbContext.PuestosTrabajo
                .AsNoTracking()
                .Where(x => x.Id == puesto.Id)
                .Select(x => new PuestoTrabajoResponseDto
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
    /// Realiza la eliminación lógica de un puesto de trabajo.
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
                mensaje =
                    "El identificador del puesto de trabajo no es válido."
            });
        }

        PuestoTrabajo? puesto =
            await _dbContext.PuestosTrabajo
                .FirstOrDefaultAsync(
                    x => x.Id == id && x.Estado,
                    cancellationToken);

        if (puesto is null)
        {
            return NotFound(new
            {
                mensaje =
                    "No se encontró el puesto de trabajo que se desea eliminar."
            });
        }

        puesto.Desactivar();
        puesto.Estado = false;
        puesto.FechaActualizacion = DateTime.UtcNow;
        puesto.UsuarioActualizacionId =
            ObtenerUsuarioId(usuarioId);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        return Ok(new
        {
            mensaje =
                "Puesto de trabajo eliminado correctamente."
        });
    }

    private static long ObtenerUsuarioId(
        long? usuarioId)
    {
        // Valor provisional hasta obtener el usuario
        // autenticado desde el token JWT.
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
/// Datos requeridos para registrar un puesto de trabajo.
/// </summary>
public sealed class CrearPuestoTrabajoDto
{
    [Required(
        ErrorMessage =
            "El nombre del puesto de trabajo es obligatorio.")]
    [StringLength(
        150,
        MinimumLength = 2,
        ErrorMessage =
            "El nombre debe tener entre 2 y 150 caracteres.")]
    public string Nombre { get; set; } =
        string.Empty;

    [StringLength(
        1000,
        ErrorMessage =
            "La descripción no puede superar 1000 caracteres.")]
    public string? Descripcion { get; set; }

    [Range(
        1,
        long.MaxValue,
        ErrorMessage =
            "Debe seleccionar un área válida.")]
    public long AreaId { get; set; }

    public long? UsuarioRegistroId { get; set; }

    public long? ColegioId { get; set; }
}

/// <summary>
/// Datos requeridos para actualizar un puesto de trabajo.
/// </summary>
public sealed class ActualizarPuestoTrabajoDto
{
    [Required(
        ErrorMessage =
            "El nombre del puesto de trabajo es obligatorio.")]
    [StringLength(
        150,
        MinimumLength = 2,
        ErrorMessage =
            "El nombre debe tener entre 2 y 150 caracteres.")]
    public string Nombre { get; set; } =
        string.Empty;

    [StringLength(
        1000,
        ErrorMessage =
            "La descripción no puede superar 1000 caracteres.")]
    public string? Descripcion { get; set; }

    [Range(
        1,
        long.MaxValue,
        ErrorMessage =
            "Debe seleccionar un área válida.")]
    public long AreaId { get; set; }

    public bool Activo { get; set; } = true;

    public long? UsuarioActualizacionId { get; set; }
}

/// <summary>
/// Información enviada al cliente móvil.
/// </summary>
public sealed class PuestoTrabajoResponseDto
{
    public long Id { get; set; }

    public string Nombre { get; set; } =
        string.Empty;

    public string? Descripcion { get; set; }

    public bool Activo { get; set; }

    public long AreaId { get; set; }

    public string AreaNombre { get; set; } =
        string.Empty;

    public DateTime FechaRegistro { get; set; }

    public DateTime? FechaActualizacion { get; set; }
}