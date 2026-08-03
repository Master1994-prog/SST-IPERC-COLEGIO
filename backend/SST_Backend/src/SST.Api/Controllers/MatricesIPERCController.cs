using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SST.Domain.IPERC.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Api.Controllers;

[ApiController]
[Route("api/MatricesIPERC")]
public sealed class MatricesIPERCController : ControllerBase
{
    private readonly SSTDbContext _dbContext;

    public MatricesIPERCController(SSTDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    // ============================================================
    // GET: api/MatricesIPERC
    // ============================================================

    [HttpGet]
    [ProducesResponseType(
        typeof(IEnumerable<MatrizIPERCResponse>),
        StatusCodes.Status200OK)]
    public async Task<IActionResult> ObtenerTodas(
        CancellationToken cancellationToken)
    {
        List<MatrizIPERCResponse> matrices =
            await _dbContext.MatricesIPERC
                .AsNoTracking()
                .OrderByDescending(x => x.FechaRegistro)
                .Select(x => new MatrizIPERCResponse
                {
                    Id = x.Id,
                    Codigo = x.Codigo,
                    Nombre = x.Nombre,
                    Objetivo = x.Objetivo,

                    InstitucionId = x.InstitucionId,

                    InstitucionNombre =
                        _dbContext.Instituciones
                            .Where(i =>
                                i.Id == x.InstitucionId)
                            .Select(i => i.Nombre)
                            .FirstOrDefault(),

                    SedeId = x.SedeId,

                    AreaId = x.AreaId,

                    AreaNombre =
                        _dbContext.Areas
                            .Where(a =>
                                a.Id == x.AreaId)
                            .Select(a => a.Nombre)
                            .FirstOrDefault(),

                    PuestoTrabajoId =
                        x.PuestoTrabajoId,

                    ProcesoId = x.ProcesoId,

                    ActividadId = x.ActividadId,

                    ActividadNombre =
                        _dbContext.Actividades
                            .Where(a =>
                                a.Id == x.ActividadId)
                            .Select(a => a.Nombre)
                            .FirstOrDefault(),

                    ResponsableId =
                        x.ResponsableId,

                    Estado = x.Estado,
                    FechaRegistro = x.FechaRegistro,
                    FechaActualizacion =
                        x.FechaActualizacion
                })
                .ToListAsync(cancellationToken);

        return Ok(matrices);
    }

    // ============================================================
    // GET: api/MatricesIPERC/1
    // ============================================================

    [HttpGet("{id:long}")]
    [ProducesResponseType(
        typeof(MatrizIPERCResponse),
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ObtenerPorId(
        long id,
        CancellationToken cancellationToken)
    {
        MatrizIPERCResponse? matriz =
            await ObtenerRespuestaPorIdAsync(
                id,
                cancellationToken);

        if (matriz is null)
        {
            return NotFound(new
            {
                mensaje =
                    "No se encontró la matriz IPERC."
            });
        }

        return Ok(matriz);
    }

    // ============================================================
    // POST: api/MatricesIPERC
    // ============================================================

    [HttpPost]
    [ProducesResponseType(
        typeof(MatrizIPERCResponse),
        StatusCodes.Status201Created)]
    [ProducesResponseType(
        StatusCodes.Status400BadRequest)]
    [ProducesResponseType(
        StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Crear(
        [FromBody] CrearMatrizIPERCRequest request,
        CancellationToken cancellationToken)
    {
        string nombre = request.Nombre.Trim();

        if (nombre.Length < 5)
        {
            return BadRequest(new
            {
                mensaje =
                    "El nombre debe tener al menos 5 caracteres."
            });
        }

        if (request.InstitucionId <= 0 ||
            request.SedeId <= 0 ||
            request.AreaId <= 0 ||
            request.PuestoTrabajoId <= 0 ||
            request.ProcesoId <= 0 ||
            request.ActividadId <= 0 ||
            request.UsuarioRegistroId <= 0)
        {
            return BadRequest(new
            {
                mensaje =
                    "Debe seleccionar todos los datos obligatorios."
            });
        }

        bool institucionValida =
            await _dbContext.Instituciones
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.Id ==
                        request.InstitucionId,
                    cancellationToken);

        if (!institucionValida)
        {
            return BadRequest(new
            {
                mensaje =
                    "La institución no existe."
            });
        }

        bool sedeValida =
            await _dbContext.Sedes
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.Id == request.SedeId &&
                        x.InstitucionId ==
                        request.InstitucionId,
                    cancellationToken);

        if (!sedeValida)
        {
            return BadRequest(new
            {
                mensaje =
                    "La sede no existe o no pertenece a la institución."
            });
        }

        bool areaValida =
            await _dbContext.Areas
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.Id == request.AreaId,
                    cancellationToken);

        if (!areaValida)
        {
            return BadRequest(new
            {
                mensaje =
                    "El área seleccionada no existe."
            });
        }

        bool puestoValido =
            await _dbContext.PuestosTrabajo
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.Id ==
                        request.PuestoTrabajoId &&
                        x.AreaId ==
                        request.AreaId,
                    cancellationToken);

        if (!puestoValido)
        {
            return BadRequest(new
            {
                mensaje =
                    "El puesto no existe o no pertenece al área."
            });
        }

        bool procesoValido =
            await _dbContext.Procesos
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.Id ==
                        request.ProcesoId,
                    cancellationToken);

        if (!procesoValido)
        {
            return BadRequest(new
            {
                mensaje =
                    "El proceso seleccionado no existe."
            });
        }

        bool actividadValida =
            await _dbContext.Actividades
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.Id ==
                        request.ActividadId,
                    cancellationToken);

        if (!actividadValida)
        {
            return BadRequest(new
            {
                mensaje =
                    "La actividad seleccionada no existe."
            });
        }

        bool usuarioValido =
            await _dbContext.Usuarios
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.Id ==
                        request.UsuarioRegistroId &&
                        x.Activo,
                    cancellationToken);

        if (!usuarioValido)
        {
            return BadRequest(new
            {
                mensaje =
                    "El usuario responsable no existe o está inactivo."
            });
        }

        bool nombreDuplicado =
            await _dbContext.MatricesIPERC
                .AsNoTracking()
                .AnyAsync(
                    x => x.Nombre == nombre,
                    cancellationToken);

        if (nombreDuplicado)
        {
            return Conflict(new
            {
                mensaje =
                    "Ya existe una matriz con el mismo nombre."
            });
        }

        string codigo =
            await GenerarCodigoAsync(
                cancellationToken);

        MatrizIPERC matriz = new()
        {
            Codigo = codigo,
            Nombre = nombre,

            Objetivo =
                string.IsNullOrWhiteSpace(
                    request.Objetivo)
                    ? null
                    : request.Objetivo.Trim(),

            InstitucionId =
                request.InstitucionId,

            SedeId =
                request.SedeId,

            AreaId =
                request.AreaId,

            PuestoTrabajoId =
                request.PuestoTrabajoId,

            ProcesoId =
                request.ProcesoId,

            ActividadId =
                request.ActividadId,

            ResponsableId =
                request.UsuarioRegistroId,

            Estado = true,
            FechaRegistro = DateTime.UtcNow,

            UsuarioRegistroId =
                request.UsuarioRegistroId
        };

        await _dbContext.MatricesIPERC.AddAsync(
            matriz,
            cancellationToken);

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        MatrizIPERCResponse? response =
            await ObtenerRespuestaPorIdAsync(
                matriz.Id,
                cancellationToken);

        if (response is null)
        {
            return StatusCode(
                StatusCodes
                    .Status500InternalServerError,
                new
                {
                    mensaje =
                        "La matriz fue registrada, pero no se pudo recuperar su información."
                });
        }

        return CreatedAtAction(
            nameof(ObtenerPorId),
            new { id = matriz.Id },
            response);
    }

    // ============================================================
    // PUT: api/MatricesIPERC/1
    // ============================================================

    [HttpPut("{id:long}")]
    [ProducesResponseType(
        typeof(MatrizIPERCResponse),
        StatusCodes.Status200OK)]
    [ProducesResponseType(
        StatusCodes.Status400BadRequest)]
    [ProducesResponseType(
        StatusCodes.Status404NotFound)]
    [ProducesResponseType(
        StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Actualizar(
        long id,
        [FromBody] ActualizarMatrizIPERCRequest request,
        CancellationToken cancellationToken)
    {
        MatrizIPERC? matriz =
            await _dbContext.MatricesIPERC
                .FirstOrDefaultAsync(
                    x => x.Id == id,
                    cancellationToken);

        if (matriz is null)
        {
            return NotFound(new
            {
                mensaje =
                    "No se encontró la matriz IPERC."
            });
        }

        string nombre = request.Nombre.Trim();

        if (nombre.Length < 5)
        {
            return BadRequest(new
            {
                mensaje =
                    "El nombre debe tener al menos 5 caracteres."
            });
        }

        if (request.InstitucionId <= 0 ||
            request.SedeId <= 0 ||
            request.AreaId <= 0 ||
            request.PuestoTrabajoId <= 0 ||
            request.ProcesoId <= 0 ||
            request.ActividadId <= 0 ||
            request.UsuarioActualizacionId <= 0)
        {
            return BadRequest(new
            {
                mensaje =
                    "Debe seleccionar todos los datos obligatorios."
            });
        }

        bool institucionValida =
            await _dbContext.Instituciones
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.Id ==
                        request.InstitucionId,
                    cancellationToken);

        if (!institucionValida)
        {
            return BadRequest(new
            {
                mensaje =
                    "La institución no existe."
            });
        }

        bool sedeValida =
            await _dbContext.Sedes
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.Id == request.SedeId &&
                        x.InstitucionId ==
                        request.InstitucionId,
                    cancellationToken);

        if (!sedeValida)
        {
            return BadRequest(new
            {
                mensaje =
                    "La sede no existe o no pertenece a la institución."
            });
        }

        bool areaValida =
            await _dbContext.Areas
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.Id == request.AreaId,
                    cancellationToken);

        if (!areaValida)
        {
            return BadRequest(new
            {
                mensaje =
                    "El área seleccionada no existe."
            });
        }

        bool puestoValido =
            await _dbContext.PuestosTrabajo
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.Id ==
                        request.PuestoTrabajoId &&
                        x.AreaId ==
                        request.AreaId,
                    cancellationToken);

        if (!puestoValido)
        {
            return BadRequest(new
            {
                mensaje =
                    "El puesto no existe o no pertenece al área."
            });
        }

        bool procesoValido =
            await _dbContext.Procesos
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.Id ==
                        request.ProcesoId,
                    cancellationToken);

        if (!procesoValido)
        {
            return BadRequest(new
            {
                mensaje =
                    "El proceso seleccionado no existe."
            });
        }

        bool actividadValida =
            await _dbContext.Actividades
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.Id ==
                        request.ActividadId,
                    cancellationToken);

        if (!actividadValida)
        {
            return BadRequest(new
            {
                mensaje =
                    "La actividad seleccionada no existe."
            });
        }

        bool usuarioValido =
            await _dbContext.Usuarios
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.Id ==
                        request.UsuarioActualizacionId &&
                        x.Activo,
                    cancellationToken);

        if (!usuarioValido)
        {
            return BadRequest(new
            {
                mensaje =
                    "El usuario que actualiza no existe o está inactivo."
            });
        }

        bool nombreDuplicado =
            await _dbContext.MatricesIPERC
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.Id != id &&
                        x.Nombre == nombre,
                    cancellationToken);

        if (nombreDuplicado)
        {
            return Conflict(new
            {
                mensaje =
                    "Ya existe una matriz con el mismo nombre."
            });
        }

        matriz.Nombre = nombre;

        matriz.Objetivo =
            string.IsNullOrWhiteSpace(
                request.Objetivo)
                ? null
                : request.Objetivo.Trim();

        matriz.InstitucionId =
            request.InstitucionId;

        matriz.SedeId =
            request.SedeId;

        matriz.AreaId =
            request.AreaId;

        matriz.PuestoTrabajoId =
            request.PuestoTrabajoId;

        matriz.ProcesoId =
            request.ProcesoId;

        matriz.ActividadId =
            request.ActividadId;

        matriz.Estado =
            request.Estado;

        matriz.FechaActualizacion =
            DateTime.UtcNow;

        matriz.UsuarioActualizacionId =
            request.UsuarioActualizacionId;

        await _dbContext.SaveChangesAsync(
            cancellationToken);

        MatrizIPERCResponse? response =
            await ObtenerRespuestaPorIdAsync(
                matriz.Id,
                cancellationToken);

        if (response is null)
        {
            return StatusCode(
                StatusCodes
                    .Status500InternalServerError,
                new
                {
                    mensaje =
                        "La matriz fue actualizada, pero no se pudo recuperar su información."
                });
        }

        return Ok(response);
    }

    // ============================================================
    // CONSULTA COMÚN PARA RESPUESTAS
    // ============================================================

    private async Task<MatrizIPERCResponse?>
        ObtenerRespuestaPorIdAsync(
            long id,
            CancellationToken cancellationToken)
    {
        return await _dbContext.MatricesIPERC
            .AsNoTracking()
            .Where(x => x.Id == id)
            .Select(x => new MatrizIPERCResponse
            {
                Id = x.Id,
                Codigo = x.Codigo,
                Nombre = x.Nombre,
                Objetivo = x.Objetivo,

                InstitucionId =
                    x.InstitucionId,

                InstitucionNombre =
                    _dbContext.Instituciones
                        .Where(i =>
                            i.Id ==
                            x.InstitucionId)
                        .Select(i => i.Nombre)
                        .FirstOrDefault(),

                SedeId = x.SedeId,

                AreaId = x.AreaId,

                AreaNombre =
                    _dbContext.Areas
                        .Where(a =>
                            a.Id == x.AreaId)
                        .Select(a => a.Nombre)
                        .FirstOrDefault(),

                PuestoTrabajoId =
                    x.PuestoTrabajoId,

                ProcesoId = x.ProcesoId,

                ActividadId = x.ActividadId,

                ActividadNombre =
                    _dbContext.Actividades
                        .Where(a =>
                            a.Id == x.ActividadId)
                        .Select(a => a.Nombre)
                        .FirstOrDefault(),

                ResponsableId =
                    x.ResponsableId,

                Estado = x.Estado,
                FechaRegistro = x.FechaRegistro,
                FechaActualizacion =
                    x.FechaActualizacion
            })
            .FirstOrDefaultAsync(
                cancellationToken);
    }

    // ============================================================
    // GENERACIÓN AUTOMÁTICA DEL CÓDIGO
    // ============================================================

    private async Task<string> GenerarCodigoAsync(
        CancellationToken cancellationToken)
    {
        int anio = DateTime.UtcNow.Year;
        string prefijo = $"IPERC-{anio}-";

        string? ultimoCodigo =
            await _dbContext.MatricesIPERC
                .AsNoTracking()
                .Where(x =>
                    x.Codigo.StartsWith(prefijo))
                .OrderByDescending(x =>
                    x.Codigo)
                .Select(x => x.Codigo)
                .FirstOrDefaultAsync(
                    cancellationToken);

        int siguiente = 1;

        if (!string.IsNullOrWhiteSpace(
                ultimoCodigo))
        {
            string numero =
                ultimoCodigo.Replace(
                    prefijo,
                    string.Empty);

            if (int.TryParse(
                    numero,
                    out int actual))
            {
                siguiente = actual + 1;
            }
        }

        return $"{prefijo}{siguiente:D4}";
    }
}

// ================================================================
// REQUEST PARA CREAR
// ================================================================

public sealed class CrearMatrizIPERCRequest
{
    public string Nombre { get; set; } =
        string.Empty;

    public string? Objetivo { get; set; }

    public long InstitucionId { get; set; }

    public long SedeId { get; set; }

    public long AreaId { get; set; }

    public long PuestoTrabajoId { get; set; }

    public long ProcesoId { get; set; }

    public long ActividadId { get; set; }

    public long UsuarioRegistroId { get; set; }
}

// ================================================================
// REQUEST PARA ACTUALIZAR
// ================================================================

public sealed class ActualizarMatrizIPERCRequest
{
    public string Nombre { get; set; } =
        string.Empty;

    public string? Objetivo { get; set; }

    public long InstitucionId { get; set; }

    public long SedeId { get; set; }

    public long AreaId { get; set; }

    public long PuestoTrabajoId { get; set; }

    public long ProcesoId { get; set; }

    public long ActividadId { get; set; }

    public bool Estado { get; set; } = true;

    public long UsuarioActualizacionId { get; set; }
}

// ================================================================
// RESPUESTA COMPLETA
// ================================================================

public sealed class MatrizIPERCResponse
{
    public long Id { get; set; }

    public string Codigo { get; set; } =
        string.Empty;

    public string Nombre { get; set; } =
        string.Empty;

    public string? Objetivo { get; set; }

    public long InstitucionId { get; set; }

    public string? InstitucionNombre { get; set; }

    public long SedeId { get; set; }

    public long AreaId { get; set; }

    public string? AreaNombre { get; set; }

    public long PuestoTrabajoId { get; set; }

    public long ProcesoId { get; set; }

    public long ActividadId { get; set; }

    public string? ActividadNombre { get; set; }

    public long ResponsableId { get; set; }

    public bool Estado { get; set; }

    public DateTime FechaRegistro { get; set; }

    public DateTime? FechaActualizacion { get; set; }
}