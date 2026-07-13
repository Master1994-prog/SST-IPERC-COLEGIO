namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para mostrar el resumen de una Matriz IPERC.
/// </summary>
public class ReporteMatrizIPERCDto
{
    public long MatrizIPERCId { get; set; }

    public string Codigo { get; set; } = string.Empty;

    public string Nombre { get; set; } = string.Empty;

    public string EstadoMatriz { get; set; } = string.Empty;

    public DateTime FechaEvaluacion { get; set; }

    public int TotalDetalles { get; set; }

    public int TotalSeguimientos { get; set; }

    public int SeguimientosVerificados { get; set; }

    public int SeguimientosPendientes { get; set; }
}
