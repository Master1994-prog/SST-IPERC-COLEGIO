using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para actualizar un mapa de riesgo.
/// No contiene Código porque se genera automáticamente.
/// No contiene Id porque el Id llega desde la ruta.
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
