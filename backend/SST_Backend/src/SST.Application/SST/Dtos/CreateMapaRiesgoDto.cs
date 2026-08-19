using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO para registrar un mapa de riesgo.
/// El código se genera automáticamente en el backend.
/// </summary>
public class CreateMapaRiesgoDto
{
    [Required]
    [MaxLength(250)]
    public string Nombre { get; set; } = string.Empty;

    [MaxLength(1500)]
    public string? Descripcion { get; set; }

    [MaxLength(300)]
    public string? Ubicacion { get; set; }

    /// <summary>
    /// URL del plano devuelta por POST /api/mapas-riesgo/upload-plano.
    /// </summary>
    [MaxLength(500)]
    public string? ArchivoUrl { get; set; }

    [MaxLength(100)]
    public string? TipoArchivo { get; set; }

    /// <summary>
    /// Posiciones normalizadas de los marcadores en formato JSON.
    /// </summary>
    public string? MarcadoresJson { get; set; }

    public DateTime FechaElaboracion { get; set; }

    public DateTime? FechaRevision { get; set; }

    public int Version { get; set; } = 1;

    [Required]
    [MaxLength(30)]
    public string EstadoMapa { get; set; } = "Borrador";

    [Required]
    public long MatrizIPERCId { get; set; }
}
