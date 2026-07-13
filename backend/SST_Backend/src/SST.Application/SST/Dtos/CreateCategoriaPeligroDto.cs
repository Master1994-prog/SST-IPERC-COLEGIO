using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para registrar una nueva categoría de peligro.
/// </summary>
public class CreateCategoriaPeligroDto
{
    /// <summary>
    /// Código corto de la categoría.
    /// Ejemplo: FIS, ERG, QUI, BIO.
    /// </summary>
    [Required]
    [MaxLength(20)]
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre de la categoría de peligro.
    /// </summary>
    [Required]
    [MaxLength(150)]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción de la categoría.
    /// </summary>
    [MaxLength(1000)]
    public string? Descripcion { get; set; }

    /// <summary>
    /// Color visual de la categoría.
    /// </summary>
    [MaxLength(10)]
    public string? Color { get; set; }

    /// <summary>
    /// Icono visual de la categoría.
    /// </summary>
    [MaxLength(100)]
    public string? Icono { get; set; }

    /// <summary>
    /// Orden de visualización.
    /// </summary>
    public int Orden { get; set; }

    /// <summary>
    /// Estado inicial de la categoría.
    /// </summary>
    public bool Activo { get; set; } = true;
}
