namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para mostrar el resumen general del sistema IPERC.
/// </summary>
public class ReporteIPERCDto
{
    public int TotalMatrices { get; set; }

    public int TotalDetalles { get; set; }

    public int TotalPeligros { get; set; }

    public int TotalConsecuencias { get; set; }

    public int TotalControles { get; set; }

    public int TotalMapasRiesgo { get; set; }

    public int TotalSeguimientos { get; set; }

    public int SeguimientosVerificados { get; set; }

    public int SeguimientosPendientes { get; set; }
}
