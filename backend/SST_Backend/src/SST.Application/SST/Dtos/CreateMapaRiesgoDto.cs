using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para registrar un mapa de riesgo.
/// El código se genera automáticamente desde el backend.
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

    [MaxLength(500)]
    public string? ArchivoUrl { get; set; }

    [MaxLength(100)]
    public string? TipoArchivo { get; set; }

    public DateTime FechaElaboracion { get; set; }

    public DateTime? FechaRevision { get; set; }

    public int Version { get; set; } = 1;

    [Required]
    [MaxLength(30)]
    public string EstadoMapa { get; set; } = "Borrador";

    [Required]
    public long MatrizIPERCId { get; set; }
}
