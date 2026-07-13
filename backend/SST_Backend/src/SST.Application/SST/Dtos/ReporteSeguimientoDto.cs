namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para mostrar información resumida de seguimientos IPERC.
/// </summary>
public class ReporteSeguimientoDto
{
    public long SeguimientoId { get; set; }

    public long DetalleIPERCId { get; set; }

    public string? Tarea { get; set; }

    public DateTime FechaSeguimiento { get; set; }

    public long UsuarioId { get; set; }

    public string Descripcion { get; set; } = string.Empty;

    public decimal PorcentajeAvance { get; set; }

    public bool Verificado { get; set; }

    public DateTime? FechaVerificacion { get; set; }
}
