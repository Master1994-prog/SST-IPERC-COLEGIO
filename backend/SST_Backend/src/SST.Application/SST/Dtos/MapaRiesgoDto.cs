namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO de salida del mapa de riesgo.
/// </summary>
public class MapaRiesgoDto
{
    public long Id { get; set; }

    public string Codigo { get; set; } = string.Empty;

    public string Nombre { get; set; } = string.Empty;

    public string? Descripcion { get; set; }

    public string? Ubicacion { get; set; }

    /// <summary>
    /// URL del plano almacenado en el backend.
    /// </summary>
    public string? ArchivoUrl { get; set; }

    public string? TipoArchivo { get; set; }

    /// <summary>
    /// Coordenadas normalizadas de marcadores.
    /// </summary>
    public string? MarcadoresJson { get; set; }

    public DateTime FechaElaboracion { get; set; }

    public DateTime? FechaRevision { get; set; }

    public int Version { get; set; }

    public string EstadoMapa { get; set; } = string.Empty;

    public bool Activo { get; set; }

    public long MatrizIPERCId { get; set; }

    public string? MatrizIPERCCodigo { get; set; }
}
