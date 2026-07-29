using Microsoft.EntityFrameworkCore;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;
using SST.Domain.IPERC.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Infrastructure.Services;

/// <summary>
/// Servicio encargado de gestionar las Matrices IPERC.
/// El código de la matriz se genera automáticamente desde el backend.
/// </summary>
public class MatrizIPERCService : IMatrizIPERCService
{
    private readonly SSTDbContext _context;

    public MatrizIPERCService(SSTDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Genera automáticamente el código de la Matriz IPERC.
    /// Formato: IPERC-2026-0001
    /// </summary>
    private async Task<string> GenerarCodigoAsync()
    {
        var anio = DateTime.Now.Year;
        var prefijo = $"IPERC-{anio}-";

        var ultimoCodigo = await _context.Set<MatrizIPERC>()
            .AsNoTracking()
            .Where(x => x.Codigo.StartsWith(prefijo))
            .OrderByDescending(x => x.Codigo)
            .Select(x => x.Codigo)
            .FirstOrDefaultAsync();

        var correlativo = 1;

        if (!string.IsNullOrWhiteSpace(ultimoCodigo))
        {
            var numeroTexto = ultimoCodigo.Replace(prefijo, "");

            if (int.TryParse(numeroTexto, out var ultimoNumero))
            {
                correlativo = ultimoNumero + 1;
            }
        }

        return $"{prefijo}{correlativo:D4}";
    }

    /// <summary>
    /// Obtiene todas las matrices IPERC.
    /// </summary>
    public async Task<IEnumerable<MatrizIPERCDto>> GetAllAsync()
    {
        return await _context.Set<MatrizIPERC>()
            .AsNoTracking()
            .Select(x => new MatrizIPERCDto
            {
                Id = x.Id,
                Codigo = x.Codigo,
                Nombre = x.Nombre,
                Objetivo = x.Objetivo,
                Alcance = x.Alcance,
                Version = x.Version,
                FechaEvaluacion = x.FechaEvaluacion,
                FechaRevision = x.FechaRevision,
                FechaAprobacion = x.FechaAprobacion,
                EstadoMatriz = x.EstadoMatriz,
                Observaciones = x.Observaciones,
                InstitucionId = x.InstitucionId,
                InstitucionNombre = _context.Instituciones
                    .Where(i => i.Id == x.InstitucionId)
                    .Select(i => i.Nombre)
                    .FirstOrDefault(),
                SedeId = x.SedeId,
                AreaId = x.AreaId,
                AreaNombre = _context.Areas
                    .Where(a => a.Id == x.AreaId)
                    .Select(a => a.Nombre)
                    .FirstOrDefault(),
                ProcesoId = x.ProcesoId,
                ActividadId = x.ActividadId,
                ActividadNombre = _context.Actividades
                    .Where(a => a.Id == x.ActividadId)
                    .Select(a => a.Nombre)
                    .FirstOrDefault(),
                PuestoTrabajoId = x.PuestoTrabajoId,
                ResponsableId = x.ResponsableId,
                AprobadorId = x.AprobadorId,
            })
            .ToListAsync();
    }

    /// <summary>
    /// Obtiene una Matriz IPERC por su Id.
    /// </summary>
    public async Task<MatrizIPERCDto?> GetByIdAsync(long id)
    {
        return await _context.Set<MatrizIPERC>()
            .AsNoTracking()
            .Where(x => x.Id == id)
            .Select(x => new MatrizIPERCDto
            {
                Id = x.Id,
                Codigo = x.Codigo,
                Nombre = x.Nombre,
                Objetivo = x.Objetivo,
                Alcance = x.Alcance,
                Version = x.Version,
                FechaEvaluacion = x.FechaEvaluacion,
                FechaRevision = x.FechaRevision,
                FechaAprobacion = x.FechaAprobacion,
                EstadoMatriz = x.EstadoMatriz,
                Observaciones = x.Observaciones,
                InstitucionId = x.InstitucionId,
                InstitucionNombre = _context.Instituciones
                    .Where(i => i.Id == x.InstitucionId)
                    .Select(i => i.Nombre)
                    .FirstOrDefault(),
                SedeId = x.SedeId,
                AreaId = x.AreaId,
                AreaNombre = _context.Areas
                    .Where(a => a.Id == x.AreaId)
                    .Select(a => a.Nombre)
                    .FirstOrDefault(),
                ProcesoId = x.ProcesoId,
                ActividadId = x.ActividadId,
                ActividadNombre = _context.Actividades
                    .Where(a => a.Id == x.ActividadId)
                    .Select(a => a.Nombre)
                    .FirstOrDefault(),
                PuestoTrabajoId = x.PuestoTrabajoId,
                ResponsableId = x.ResponsableId,
                AprobadorId = x.AprobadorId,
            })
            .FirstOrDefaultAsync();
    }

    /// <summary>
    /// Registra una nueva Matriz IPERC.
    /// El código se genera automáticamente.
    /// </summary>
    public async Task<MatrizIPERCDto> CreateAsync(CreateMatrizIPERCDto dto)
    {
        var codigoGenerado = await GenerarCodigoAsync();

        var matriz = new MatrizIPERC
        {
            Codigo = codigoGenerado,
            Nombre = dto.Nombre.Trim(),
            Objetivo = dto.Objetivo?.Trim(),
            Alcance = dto.Alcance?.Trim(),
            Version = dto.Version <= 0 ? 1 : dto.Version,
            FechaEvaluacion = dto.FechaEvaluacion,
            FechaRevision = dto.FechaRevision,
            FechaAprobacion = null,
            EstadoMatriz = string.IsNullOrWhiteSpace(dto.EstadoMatriz)
                ? "Borrador"
                : dto.EstadoMatriz.Trim(),
            Observaciones = dto.Observaciones?.Trim(),
            InstitucionId = dto.InstitucionId,
            SedeId = dto.SedeId,
            AreaId = dto.AreaId,
            ProcesoId = dto.ProcesoId,
            ActividadId = dto.ActividadId,
            PuestoTrabajoId = dto.PuestoTrabajoId,
            ResponsableId = dto.ResponsableId,
            AprobadorId = dto.AprobadorId
        };

        _context.Set<MatrizIPERC>().Add(matriz);
        await _context.SaveChangesAsync();

        return await GetByIdAsync(matriz.Id)
            ?? throw new InvalidOperationException("No se pudo obtener la matriz IPERC creada.");
    }

    /// <summary>
    /// Actualiza una Matriz IPERC existente.
    /// El código no se modifica porque es automático.
    /// </summary>
    public async Task<bool> UpdateAsync(long id, UpdateMatrizIPERCDto dto)
    {
        var matriz = await _context.Set<MatrizIPERC>()
            .FirstOrDefaultAsync(x => x.Id == id);

        if (matriz is null)
            return false;

        matriz.Nombre = dto.Nombre.Trim();
        matriz.Objetivo = dto.Objetivo?.Trim();
        matriz.Alcance = dto.Alcance?.Trim();
        matriz.Version = dto.Version <= 0 ? 1 : dto.Version;
        matriz.FechaEvaluacion = dto.FechaEvaluacion;
        matriz.FechaRevision = dto.FechaRevision;
        matriz.FechaAprobacion = dto.FechaAprobacion;
        matriz.EstadoMatriz = string.IsNullOrWhiteSpace(dto.EstadoMatriz)
            ? "Borrador"
            : dto.EstadoMatriz.Trim();
        matriz.Observaciones = dto.Observaciones?.Trim();
        matriz.InstitucionId = dto.InstitucionId;
        matriz.SedeId = dto.SedeId;
        matriz.AreaId = dto.AreaId;
        matriz.ProcesoId = dto.ProcesoId;
        matriz.ActividadId = dto.ActividadId;
        matriz.PuestoTrabajoId = dto.PuestoTrabajoId;
        matriz.ResponsableId = dto.ResponsableId;
        matriz.AprobadorId = dto.AprobadorId;
        matriz.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }

    /// <summary>
    /// Cierra una Matriz IPERC.
    /// No elimina físicamente el registro.
    /// </summary>
    public async Task<bool> DeleteAsync(long id)
    {
        var matriz = await _context.Set<MatrizIPERC>()
            .FirstOrDefaultAsync(x => x.Id == id);

        if (matriz is null)
            return false;

        matriz.EstadoMatriz = "Cerrada";
        matriz.FechaActualizacion = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return true;
    }
}
