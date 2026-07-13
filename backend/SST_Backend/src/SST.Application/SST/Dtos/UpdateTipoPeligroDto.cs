using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para actualizar un tipo de peligro.
/// No contiene Id porque el Id se recibe desde la ruta.
/// </summary>
public class UpdateTipoPeligroDto
{
    /// <summary>
    /// Código único del tipo de peligro.
    /// </summary>
    [Required]
    [MaxLength(20)]
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre del tipo de peligro.
    /// </summary>
    [Required]
    [MaxLength(150)]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción del tipo de peligro.
    /// </summary>
    [MaxLength(1000)]
    public string? Descripcion { get; set; }

    /// <summary>
    /// Id de la categoría de peligro.
    /// </summary>
    [Required]
    public long CategoriaPeligroId { get; set; }

    /// <summary>
    /// Estado del registro.
    /// </summary>
    public bool Activo { get; set; }
}
