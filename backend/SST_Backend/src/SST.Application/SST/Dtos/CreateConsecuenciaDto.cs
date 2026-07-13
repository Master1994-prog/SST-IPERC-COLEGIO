using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para registrar una nueva consecuencia.
/// </summary>
public class CreateConsecuenciaDto
{
    /// <summary>
    /// Código único de la consecuencia.
    /// Ejemplo: CONS-001.
    /// </summary>
    [Required]
    [MaxLength(50)]
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre de la consecuencia.
    /// Ejemplo: Golpes y contusiones.
    /// </summary>
    [Required]
    [MaxLength(200)]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción de la consecuencia.
    /// </summary>
    [MaxLength(1000)]
    public string? Descripcion { get; set; }
}
