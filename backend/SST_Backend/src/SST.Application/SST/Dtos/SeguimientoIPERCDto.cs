namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para mostrar la información de un seguimiento IPERC.
/// </summary>
public class SeguimientoIPERCDto
{
    public long Id { get; set; }

    public long DetalleIPERCId { get; set; }

    public int? DetalleItem { get; set; }

    public string? DetalleTarea { get; set; }

    public DateTime FechaSeguimiento { get; set; }

    public long UsuarioId { get; set; }

    public string? UsuarioNombre { get; set; }

    public string Descripcion { get; set; } = string.Empty;

    public decimal PorcentajeAvance { get; set; }

    public bool Verificado { get; set; }

    public DateTime? FechaVerificacion { get; set; }

    public string? Observaciones { get; set; }

    public string? Archivo { get; set; }

    public string? NombreArchivo { get; set; }

    public string? TipoArchivo { get; set; }
}
