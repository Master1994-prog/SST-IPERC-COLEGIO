using Microsoft.AspNetCore.Mvc;
using SST.Application.SST.Interfaces;

namespace SST.Api.Controllers;

/// <summary>
/// Controlador para generar reportes IPERC.
/// </summary>
[ApiController]
[Route("api/reportes-iperc")]
public class ReportesIPERCController : ControllerBase
{
    private readonly IReporteIPERCService _reporteIPERCService;

    public ReportesIPERCController(IReporteIPERCService reporteIPERCService)
    {
        _reporteIPERCService = reporteIPERCService;
    }

    /// <summary>
    /// Obtiene el resumen general del sistema IPERC.
    /// </summary>
    [HttpGet("resumen-general")]
    public async Task<IActionResult> GetResumenGeneral()
    {
        var reporte = await _reporteIPERCService.GetResumenGeneralAsync();

        return Ok(reporte);
    }

    /// <summary>
    /// Obtiene el resumen de una Matriz IPERC específica.
    /// </summary>
    [HttpGet("matriz/{matrizIPERCId:long}")]
    public async Task<IActionResult> GetResumenMatriz(long matrizIPERCId)
    {
        var reporte = await _reporteIPERCService.GetResumenMatrizAsync(matrizIPERCId);

        if (reporte is null)
            return NotFound(new { mensaje = "Matriz IPERC no encontrada." });

        return Ok(reporte);
    }

    /// <summary>
    /// Obtiene los seguimientos pendientes de verificación.
    /// </summary>
    [HttpGet("seguimientos-pendientes")]
    public async Task<IActionResult> GetSeguimientosPendientes()
    {
        var reporte = await _reporteIPERCService.GetSeguimientosPendientesAsync();

        return Ok(reporte);
    }

    /// <summary>
    /// Obtiene los seguimientos verificados.
    /// </summary>
    [HttpGet("seguimientos-verificados")]
    public async Task<IActionResult> GetSeguimientosVerificados()
    {
        var reporte = await _reporteIPERCService.GetSeguimientosVerificadosAsync();

        return Ok(reporte);
    }
}
