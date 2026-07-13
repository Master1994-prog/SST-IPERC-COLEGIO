using Microsoft.EntityFrameworkCore;
using SST.Application.SST.Dtos;
using SST.Application.SST.Interfaces;
using SST.Domain.IPERC.Entities;
using SST.Domain.SST.Entities;
using SST.Infrastructure.Persistence;

namespace SST.Infrastructure.Services;

/// <summary>
/// Servicio encargado de generar reportes IPERC.
/// Este servicio consulta información consolidada de matrices, detalles,
/// peligros, controles, mapas de riesgo y seguimientos.
/// </summary>
public class ReporteIPERCService : IReporteIPERCService
{
    private readonly SSTDbContext _context;

    public ReporteIPERCService(SSTDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Obtiene el resumen general del sistema IPERC.
    /// </summary>
    public async Task<ReporteIPERCDto> GetResumenGeneralAsync()
    {
        var totalMatrices = await _context.Set<MatrizIPERC>().CountAsync();
        var totalDetalles = await _context.Set<DetalleIPERC>().CountAsync();
        var totalPeligros = await _context.Set<Peligro>().CountAsync(x => x.Activo);
        var totalConsecuencias = await _context.Set<Consecuencia>().CountAsync(x => x.Activo);
        var totalControles = await _context.Set<Control>().CountAsync(x => x.Activo);
        var totalMapasRiesgo = await _context.Set<MapaRiesgo>().CountAsync(x => x.Activo);
        var totalSeguimientos = await _context.Set<SeguimientoIPERC>().CountAsync();
        var seguimientosVerificados = await _context.Set<SeguimientoIPERC>().CountAsync(x => x.Verificado);
        var seguimientosPendientes = await _context.Set<SeguimientoIPERC>().CountAsync(x => !x.Verificado);

        return new ReporteIPERCDto
        {
            TotalMatrices = totalMatrices,
            TotalDetalles = totalDetalles,
            TotalPeligros = totalPeligros,
            TotalConsecuencias = totalConsecuencias,
            TotalControles = totalControles,
            TotalMapasRiesgo = totalMapasRiesgo,
            TotalSeguimientos = totalSeguimientos,
            SeguimientosVerificados = seguimientosVerificados,
            SeguimientosPendientes = seguimientosPendientes
        };
    }

    /// <summary>
    /// Obtiene el resumen de una Matriz IPERC específica.
    /// </summary>
    public async Task<ReporteMatrizIPERCDto?> GetResumenMatrizAsync(long matrizIPERCId)
    {
        var matriz = await _context.Set<MatrizIPERC>()
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == matrizIPERCId);

        if (matriz is null)
            return null;

        var detalleIds = await _context.Set<DetalleIPERC>()
            .Where(x => x.MatrizIPERCId == matrizIPERCId)
            .Select(x => x.Id)
            .ToListAsync();

        var totalDetalles = detalleIds.Count;

        var totalSeguimientos = await _context.Set<SeguimientoIPERC>()
            .CountAsync(x => detalleIds.Contains(x.DetalleIPERCId));

        var seguimientosVerificados = await _context.Set<SeguimientoIPERC>()
            .CountAsync(x => detalleIds.Contains(x.DetalleIPERCId) && x.Verificado);

        var seguimientosPendientes = await _context.Set<SeguimientoIPERC>()
            .CountAsync(x => detalleIds.Contains(x.DetalleIPERCId) && !x.Verificado);

        return new ReporteMatrizIPERCDto
        {
            MatrizIPERCId = matriz.Id,
            Codigo = matriz.Codigo,
            Nombre = matriz.Nombre,
            EstadoMatriz = matriz.EstadoMatriz,
            FechaEvaluacion = matriz.FechaEvaluacion,
            TotalDetalles = totalDetalles,
            TotalSeguimientos = totalSeguimientos,
            SeguimientosVerificados = seguimientosVerificados,
            SeguimientosPendientes = seguimientosPendientes
        };
    }

    /// <summary>
    /// Obtiene los seguimientos pendientes de verificación.
    /// </summary>
    public async Task<IEnumerable<ReporteSeguimientoDto>> GetSeguimientosPendientesAsync()
    {
        return await _context.Set<SeguimientoIPERC>()
            .AsNoTracking()
            .Include(x => x.DetalleIPERC)
            .Where(x => !x.Verificado)
            .OrderByDescending(x => x.FechaSeguimiento)
            .Select(x => new ReporteSeguimientoDto
            {
                SeguimientoId = x.Id,
                DetalleIPERCId = x.DetalleIPERCId,
                Tarea = x.DetalleIPERC.Tarea,
                FechaSeguimiento = x.FechaSeguimiento,
                UsuarioId = x.UsuarioId,
                Descripcion = x.Descripcion,
                PorcentajeAvance = x.PorcentajeAvance,
                Verificado = x.Verificado,
                FechaVerificacion = x.FechaVerificacion
            })
            .ToListAsync();
    }

    /// <summary>
    /// Obtiene los seguimientos verificados.
    /// </summary>
    public async Task<IEnumerable<ReporteSeguimientoDto>> GetSeguimientosVerificadosAsync()
    {
        return await _context.Set<SeguimientoIPERC>()
            .AsNoTracking()
            .Include(x => x.DetalleIPERC)
            .Where(x => x.Verificado)
            .OrderByDescending(x => x.FechaSeguimiento)
            .Select(x => new ReporteSeguimientoDto
            {
                SeguimientoId = x.Id,
                DetalleIPERCId = x.DetalleIPERCId,
                Tarea = x.DetalleIPERC.Tarea,
                FechaSeguimiento = x.FechaSeguimiento,
                UsuarioId = x.UsuarioId,
                Descripcion = x.Descripcion,
                PorcentajeAvance = x.PorcentajeAvance,
                Verificado = x.Verificado,
                FechaVerificacion = x.FechaVerificacion
            })
            .ToListAsync();
    }
}
