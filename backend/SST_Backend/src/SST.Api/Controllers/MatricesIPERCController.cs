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

    [HttpGet]
    public async Task<IActionResult> ObtenerTodas(
        CancellationToken cancellationToken)
    {
        var matrices = await _dbContext.MatricesIPERC
            .AsNoTracking()
            .OrderByDescending(x => x.FechaRegistro)
            .Select(x => new
            {
                x.Id,
                x.Codigo,
                x.Nombre,
                x.Objetivo,
                x.InstitucionId,
                x.SedeId,
                x.AreaId,
                x.PuestoTrabajoId,
                x.ProcesoId,
                x.ActividadId,
                x.ResponsableId,
                x.Estado,
                x.FechaRegistro
            })
            .ToListAsync(cancellationToken);

        return Ok(matrices);
    }

    [HttpGet("{id:long}")]
    public async Task<IActionResult> ObtenerPorId(
        long id,
        CancellationToken cancellationToken)
    {
        var matriz = await _dbContext.MatricesIPERC
            .AsNoTracking()
            .Where(x => x.Id == id)
            .Select(x => new
            {
                x.Id,
                x.Codigo,
                x.Nombre,
                x.Objetivo,
                x.InstitucionId,
                x.SedeId,
                x.AreaId,
                x.PuestoTrabajoId,
                x.ProcesoId,
                x.ActividadId,
                x.ResponsableId,
                x.Estado,
                x.FechaRegistro
            })
            .FirstOrDefaultAsync(cancellationToken);

        if (matriz is null)
        {
            return NotFound(new
            {
                mensaje = "No se encontró la matriz IPERC."
            });
        }

        return Ok(matriz);
    }

    [HttpPost]
    [ProducesResponseType(
        typeof(CrearMatrizIPERCResponse),
        StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
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
                    x => x.Id == request.InstitucionId,
                    cancellationToken);

        if (!institucionValida)
        {
            return BadRequest(new
            {
                mensaje = "La institución no existe."
            });
        }

        bool sedeValida = await _dbContext.Sedes
            .AsNoTracking()
            .AnyAsync(
                x =>
                    x.Id == request.SedeId &&
                    x.InstitucionId == request.InstitucionId,
                cancellationToken);

        if (!sedeValida)
        {
            return BadRequest(new
            {
                mensaje =
                    "La sede no existe o no pertenece a la institución."
            });
        }

        bool areaValida = await _dbContext.Areas
            .AsNoTracking()
            .AnyAsync(
                x => x.Id == request.AreaId,
                cancellationToken);

        if (!areaValida)
        {
            return BadRequest(new
            {
                mensaje = "El área seleccionada no existe."
            });
        }

        bool puestoValido =
            await _dbContext.PuestosTrabajo
                .AsNoTracking()
                .AnyAsync(
                    x =>
                        x.Id == request.PuestoTrabajoId &&
                        x.AreaId == request.AreaId,
                    cancellationToken);

        if (!puestoValido)
        {
            return BadRequest(new
            {
                mensaje =
                    "El puesto no existe o no pertenece al área."
            });
        }

        bool procesoValido = await _dbContext.Procesos
            .AsNoTracking()
            .AnyAsync(
                x => x.Id == request.ProcesoId,
                cancellationToken);

        if (!procesoValido)
        {
            return BadRequest(new
            {
                mensaje = "El proceso seleccionado no existe."
            });
        }

        bool actividadValida =
            await _dbContext.Actividades
                .AsNoTracking()
                .AnyAsync(
                    x => x.Id == request.ActividadId,
                    cancellationToken);

        if (!actividadValida)
        {
            return BadRequest(new
            {
                mensaje = "La actividad seleccionada no existe."
            });
        }

        bool usuarioValido = await _dbContext.Usuarios
            .AsNoTracking()
            .AnyAsync(
                x => x.Id == request.UsuarioRegistroId &&
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
            await GenerarCodigoAsync(cancellationToken);

        MatrizIPERC matriz = new()
        {
            Codigo = codigo,
            Nombre = nombre,

            Objetivo = string.IsNullOrWhiteSpace(request.Objetivo)
                ? null
                : request.Objetivo.Trim(),

            InstitucionId = request.InstitucionId,
            SedeId = request.SedeId,
            AreaId = request.AreaId,
            PuestoTrabajoId = request.PuestoTrabajoId,
            ProcesoId = request.ProcesoId,
            ActividadId = request.ActividadId,

            // Temporalmente, el usuario autenticado que registra
            // también será el responsable.
            ResponsableId = request.UsuarioRegistroId,

            Estado = true,
            FechaRegistro = DateTime.UtcNow,
            UsuarioRegistroId = request.UsuarioRegistroId
        };

        await _dbContext.MatricesIPERC.AddAsync(
            matriz,
            cancellationToken);

        await _dbContext.SaveChangesAsync(cancellationToken);

        CrearMatrizIPERCResponse response = new()
        {
            Id = matriz.Id,
            Codigo = matriz.Codigo,
            Nombre = matriz.Nombre,
            Objetivo = matriz.Objetivo,
            InstitucionId = matriz.InstitucionId,
            SedeId = matriz.SedeId,
            AreaId = matriz.AreaId,
            PuestoTrabajoId = matriz.PuestoTrabajoId,
            ProcesoId = matriz.ProcesoId,
            ActividadId = matriz.ActividadId,
            ResponsableId = matriz.ResponsableId,
            Estado = matriz.Estado,
            FechaRegistro = matriz.FechaRegistro
        };

        return CreatedAtAction(
            nameof(ObtenerPorId),
            new { id = matriz.Id },
            response);
    }

    private async Task<string> GenerarCodigoAsync(
        CancellationToken cancellationToken)
    {
        int anio = DateTime.UtcNow.Year;
        string prefijo = $"IPERC-{anio}-";

        string? ultimoCodigo =
            await _dbContext.MatricesIPERC
                .AsNoTracking()
                .Where(x => x.Codigo.StartsWith(prefijo))
                .OrderByDescending(x => x.Codigo)
                .Select(x => x.Codigo)
                .FirstOrDefaultAsync(cancellationToken);

        int siguiente = 1;

        if (!string.IsNullOrWhiteSpace(ultimoCodigo))
        {
            string numero = ultimoCodigo.Replace(
                prefijo,
                string.Empty);

            if (int.TryParse(numero, out int actual))
            {
                siguiente = actual + 1;
            }
        }

        return $"{prefijo}{siguiente:D4}";
    }
}

public sealed class CrearMatrizIPERCRequest
{
    public string Nombre { get; set; } = string.Empty;

    public string? Objetivo { get; set; }

    public long InstitucionId { get; set; }

    public long SedeId { get; set; }

    public long AreaId { get; set; }

    public long PuestoTrabajoId { get; set; }

    public long ProcesoId { get; set; }

    public long ActividadId { get; set; }

    public long UsuarioRegistroId { get; set; }
}

public sealed class CrearMatrizIPERCResponse
{
    public long Id { get; set; }

    public string Codigo { get; set; } = string.Empty;

    public string Nombre { get; set; } = string.Empty;

    public string? Objetivo { get; set; }

    public long InstitucionId { get; set; }

    public long SedeId { get; set; }

    public long AreaId { get; set; }

    public long PuestoTrabajoId { get; set; }

    public long ProcesoId { get; set; }

    public long ActividadId { get; set; }

    public long ResponsableId { get; set; }

    public bool Estado { get; set; }

    public DateTime FechaRegistro { get; set; }
}
