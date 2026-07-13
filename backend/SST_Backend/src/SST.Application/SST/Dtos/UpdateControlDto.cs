using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para actualizar un control.
/// No contiene Id porque el Id llega desde la ruta.
/// Ejemplo: PUT /api/controles/1
/// </summary>
public class UpdateControlDto
{
    /// <summary>
    /// Código actualizado del control.
    /// </summary>
    [Required]
    [MaxLength(50)]
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre actualizado del control.
    /// </summary>
    [Required]
    [MaxLength(200)]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción actualizada del control.
    /// </summary>
    [MaxLength(1000)]
    public string? Descripcion { get; set; }

    /// <summary>
    /// Estado del control.
    /// true = activo, false = inactivo.
    /// </summary>
    public bool Activo { get; set; }
}
