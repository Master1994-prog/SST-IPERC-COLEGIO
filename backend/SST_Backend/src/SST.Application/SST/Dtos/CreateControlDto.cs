using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para registrar un nuevo control.
/// </summary>
public class CreateControlDto
{
    /// <summary>
    /// Código único del control.
    /// Ejemplo: CTRL-001.
    /// </summary>
    [Required]
    [MaxLength(50)]
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre del control.
    /// </summary>
    [Required]
    [MaxLength(200)]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción del control.
    /// </summary>
    [MaxLength(1000)]
    public string? Descripcion { get; set; }
}
