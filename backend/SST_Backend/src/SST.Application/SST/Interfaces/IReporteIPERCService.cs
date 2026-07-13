using SST.Application.SST.Dtos;

namespace SST.Application.SST.Interfaces;

/// <summary>
/// Interfaz del servicio de reportes IPERC.
/// </summary>
public interface IReporteIPERCService
{
    /// <summary>
    /// Obtiene el resumen general del sistema IPERC.
    /// </summary>
    Task<ReporteIPERCDto> GetResumenGeneralAsync();

    /// <summary>
    /// Obtiene el resumen de una Matriz IPERC específica.
    /// </summary>
    Task<ReporteMatrizIPERCDto?> GetResumenMatrizAsync(long matrizIPERCId);

    /// <summary>
    /// Obtiene los seguimientos pendientes.
    /// </summary>
    Task<IEnumerable<ReporteSeguimientoDto>> GetSeguimientosPendientesAsync();

    /// <summary>
    /// Obtiene los seguimientos verificados.
    /// </summary>
    Task<IEnumerable<ReporteSeguimientoDto>> GetSeguimientosVerificadosAsync();
}
