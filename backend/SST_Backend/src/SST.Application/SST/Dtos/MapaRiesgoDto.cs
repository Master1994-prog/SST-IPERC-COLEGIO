namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para mostrar información de un mapa de riesgo.
/// </summary>
public class MapaRiesgoDto
{
    public long Id { get; set; }

    public string Codigo { get; set; } = string.Empty;

    public string Nombre { get; set; } = string.Empty;

    public string? Descripcion { get; set; }

    public string? Ubicacion { get; set; }

    public string? ArchivoUrl { get; set; }

    public string? TipoArchivo { get; set; }

    public DateTime FechaElaboracion { get; set; }

    public DateTime? FechaRevision { get; set; }

    public int Version { get; set; }

    public string EstadoMapa { get; set; } = string.Empty;

    public bool Activo { get; set; }

    public long MatrizIPERCId { get; set; }

    public string? MatrizIPERCCodigo { get; set; }
}
