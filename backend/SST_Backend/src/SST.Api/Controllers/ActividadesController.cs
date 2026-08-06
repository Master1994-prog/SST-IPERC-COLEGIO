using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SST.Domain.Organization.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Api.Controllers;

/// <summary>
/// Gestiona las actividades pertenecientes a los procesos.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public sealed class ActividadesController : ControllerBase
{
    private readonly SSTDbContext _dbContext;

    public ActividadesController(SSTDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    /// <summary>
    /// Obtiene las actividades activas.
    /// Permite filtrar por proceso.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> ObtenerTodas(
        [FromQuery] long? procesoId,
        CancellationToken cancellationToken)
    {
        IQueryable<Actividad> consulta = _dbContext.Actividades
            .AsNoTracking()
            .Where(x => x.Estado && x.Activo);

        if (procesoId.HasValue && procesoId.Value > 0)
        {
            consulta = consulta.Where(
                x => x.ProcesoId == procesoId.Value);
        }

        List<ActividadResponseDto> actividades = await consulta
            .OrderBy(x => x.Nombre)
            .Select(x => new ActividadResponseDto
            {
                Id = x.Id,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                Activo = x.Activo,
                ProcesoId = x.ProcesoId,
                ProcesoNombre = x.Proceso.Nombre,
                AreaId = x.Proceso.AreaId,
                AreaNombre = x.Proceso.Area.Nombre,
                FechaRegistro = x.FechaRegistro,
                FechaActualizacion = x.FechaActualizacion
            })
            .ToListAsync(cancellationToken);

        return Ok(actividades);
    }

    /// <summary>
    /// Obtiene una actividad mediante su identificador.
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
                mensaje = "El identificador de la actividad no es válido."
            });
        }

        ActividadResponseDto? actividad = await _dbContext.Actividades
            .AsNoTracking()
            .Where(x => x.Id == id && x.Estado)
            .Select(x => new ActividadResponseDto
            {
                Id = x.Id,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                Activo = x.Activo,
                ProcesoId = x.ProcesoId,
                ProcesoNombre = x.Proceso.Nombre,
                AreaId = x.Proceso.AreaId,
                AreaNombre = x.Proceso.Area.Nombre,
                FechaRegistro = x.FechaRegistro,
                FechaActualizacion = x.FechaActualizacion
            })
            .FirstOrDefaultAsync(cancellationToken);

        if (actividad is null)
        {
            return NotFound(new
            {
                mensaje = "No se encontró la actividad solicitada."
            });
        }

        return Ok(actividad);
    }

    /// <summary>
    /// Registra una nueva actividad.
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> Crear(
        [FromBody] CrearActividadDto solicitud,
        CancellationToken cancellationToken)
    {
        string nombre = solicitud.Nombre.Trim();
        string? descripcion = LimpiarTextoOpcional(
            solicitud.Descripcion);

        bool procesoExiste = await _dbContext.Procesos
            .AsNoTracking()
            .AnyAsync(
                x => x.Id == solicitud.ProcesoId &&
                     x.Estado &&
                     x.Activo,
                cancellationToken);

        if (!procesoExiste)
        {
            return BadRequest(new
            {
                mensaje = "El proceso seleccionado no existe o está inactivo."
            });
        }

        bool nombreDuplicado = await _dbContext.Actividades
            .AsNoTracking()
            .AnyAsync(
                x => x.ProcesoId == solicitud.ProcesoId &&
                     x.Estado &&
                     x.Nombre.ToLower() == nombre.ToLower(),
                cancellationToken);

        if (nombreDuplicado)
        {
            return Conflict(new
            {
                mensaje =
                    "Ya existe una actividad con ese nombre en el proceso."
            });
        }

        var actividad = new Actividad
        {
            Nombre = nombre,
            Descripcion = descripcion,
            ProcesoId = solicitud.ProcesoId,
            Activo = true,
            Estado = true,
            FechaRegistro = DateTime.UtcNow,
            UsuarioRegistroId = ObtenerUsuarioId(
                solicitud.UsuarioRegistroId),
            EsGlobal = false,
            ColegioId = solicitud.ColegioId
        };

        _dbContext.Actividades.Add(actividad);
        await _dbContext.SaveChangesAsync(cancellationToken);

        ActividadResponseDto? resultado = await _dbContext.Actividades
            .AsNoTracking()
            .Where(x => x.Id == actividad.Id)
            .Select(x => new ActividadResponseDto
            {
                Id = x.Id,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                Activo = x.Activo,
                ProcesoId = x.ProcesoId,
                ProcesoNombre = x.Proceso.Nombre,
                AreaId = x.Proceso.AreaId,
                AreaNombre = x.Proceso.Area.Nombre,
                FechaRegistro = x.FechaRegistro,
                FechaActualizacion = x.FechaActualizacion
            })
            .FirstOrDefaultAsync(cancellationToken);

        return CreatedAtAction(
            nameof(ObtenerPorId),
            new { id = actividad.Id },
            resultado);
    }

    /// <summary>
    /// Actualiza una actividad existente.
    /// </summary>
    [HttpPut("{id:long}")]
    public async Task<IActionResult> Actualizar(
        long id,
        [FromBody] ActualizarActividadDto solicitud,
        CancellationToken cancellationToken)
    {
        if (id <= 0)
        {
            return BadRequest(new
            {
                mensaje = "El identificador de la actividad no es válido."
            });
        }

        Actividad? actividad = await _dbContext.Actividades
            .FirstOrDefaultAsync(
                x => x.Id == id && x.Estado,
                cancellationToken);

        if (actividad is null)
        {
            return NotFound(new
            {
                mensaje =
                    "No se encontró la actividad que se desea actualizar."
            });
        }

        string nombre = solicitud.Nombre.Trim();
        string? descripcion = LimpiarTextoOpcional(
            solicitud.Descripcion);

        bool procesoExiste = await _dbContext.Procesos
            .AsNoTracking()
            .AnyAsync(
                x => x.Id == solicitud.ProcesoId &&
                     x.Estado &&
                     x.Activo,
                cancellationToken);

        if (!procesoExiste)
        {
            return BadRequest(new
            {
                mensaje = "El proceso seleccionado no existe o está inactivo."
            });
        }

        bool nombreDuplicado = await _dbContext.Actividades
            .AsNoTracking()
            .AnyAsync(
                x => x.Id != id &&
                     x.ProcesoId == solicitud.ProcesoId &&
                     x.Estado &&
                     x.Nombre.ToLower() == nombre.ToLower(),
                cancellationToken);

        if (nombreDuplicado)
        {
            return Conflict(new
            {
                mensaje =
                    "Ya existe otra actividad con ese nombre en el proceso."
            });
        }

        actividad.Nombre = nombre;
        actividad.Descripcion = descripcion;
        actividad.ProcesoId = solicitud.ProcesoId;
        actividad.Activo = solicitud.Activo;
        actividad.FechaActualizacion = DateTime.UtcNow;
        actividad.UsuarioActualizacionId = ObtenerUsuarioId(
            solicitud.UsuarioActualizacionId);

        await _dbContext.SaveChangesAsync(cancellationToken);

        ActividadResponseDto? resultado = await _dbContext.Actividades
            .AsNoTracking()
            .Where(x => x.Id == actividad.Id)
            .Select(x => new ActividadResponseDto
            {
                Id = x.Id,
                Nombre = x.Nombre,
                Descripcion = x.Descripcion,
                Activo = x.Activo,
                ProcesoId = x.ProcesoId,
                ProcesoNombre = x.Proceso.Nombre,
                AreaId = x.Proceso.AreaId,
                AreaNombre = x.Proceso.Area.Nombre,
                FechaRegistro = x.FechaRegistro,
                FechaActualizacion = x.FechaActualizacion
            })
            .FirstOrDefaultAsync(cancellationToken);

        return Ok(resultado);
    }

    /// <summary>
    /// Realiza la eliminación lógica de una actividad.
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
                mensaje = "El identificador de la actividad no es válido."
            });
        }

        Actividad? actividad = await _dbContext.Actividades
            .FirstOrDefaultAsync(
                x => x.Id == id && x.Estado,
                cancellationToken);

        if (actividad is null)
        {
            return NotFound(new
            {
                mensaje =
                    "No se encontró la actividad que se desea eliminar."
            });
        }

        // Se utiliza eliminación lógica para conservar las relaciones
        // históricas con matrices IPERC y otros registros.
        actividad.Activo = false;
        actividad.Estado = false;
        actividad.FechaActualizacion = DateTime.UtcNow;
        actividad.UsuarioActualizacionId = ObtenerUsuarioId(
            usuarioId);

        await _dbContext.SaveChangesAsync(cancellationToken);

        return Ok(new
        {
            mensaje = "Actividad eliminada correctamente."
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
/// Datos necesarios para registrar una actividad.
/// </summary>
public sealed class CrearActividadDto
{
    [Required(ErrorMessage = "El nombre de la actividad es obligatorio.")]
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
        ErrorMessage = "Debe seleccionar un proceso válido.")]
    public long ProcesoId { get; set; }

    public long? UsuarioRegistroId { get; set; }

    public long? ColegioId { get; set; }
}

/// <summary>
/// Datos necesarios para actualizar una actividad.
/// </summary>
public sealed class ActualizarActividadDto
{
    [Required(ErrorMessage = "El nombre de la actividad es obligatorio.")]
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
        ErrorMessage = "Debe seleccionar un proceso válido.")]
    public long ProcesoId { get; set; }

    public bool Activo { get; set; } = true;

    public long? UsuarioActualizacionId { get; set; }
}

/// <summary>
/// Información de una actividad enviada al cliente móvil.
/// </summary>
public sealed class ActividadResponseDto
{
    public long Id { get; set; }

    public string Nombre { get; set; } = string.Empty;

    public string? Descripcion { get; set; }

    public bool Activo { get; set; }

    public long ProcesoId { get; set; }

    public string ProcesoNombre { get; set; } = string.Empty;

    public long AreaId { get; set; }

    public string AreaNombre { get; set; } = string.Empty;

    public DateTime FechaRegistro { get; set; }

    public DateTime? FechaActualizacion { get; set; }
}
