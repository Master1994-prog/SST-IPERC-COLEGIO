using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO para actualizar un mapa de riesgo.
/// El Id llega en la ruta y el código no se modifica.
/// </summary>
public class UpdateMapaRiesgoDto
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

    /// <summary>
    /// Posiciones normalizadas de los marcadores en formato JSON.
    /// </summary>
    public string? MarcadoresJson { get; set; }

    public DateTime FechaElaboracion { get; set; }

    public DateTime? FechaRevision { get; set; }

    public int Version { get; set; }

    [Required]
    [MaxLength(30)]
    public string EstadoMapa { get; set; } = "Borrador";

    public bool Activo { get; set; }

    [Required]
    public long MatrizIPERCId { get; set; }
}
