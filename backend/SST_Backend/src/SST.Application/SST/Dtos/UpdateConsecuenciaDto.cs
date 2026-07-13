using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para actualizar una consecuencia.
/// No contiene Id porque el Id llega desde la ruta del controlador.
/// </summary>
public class UpdateConsecuenciaDto
{
    /// <summary>
    /// Código actualizado de la consecuencia.
    /// </summary>
    [Required]
    [MaxLength(50)]
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre actualizado de la consecuencia.
    /// </summary>
    [Required]
    [MaxLength(200)]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción actualizada de la consecuencia.
    /// </summary>
    [MaxLength(1000)]
    public string? Descripcion { get; set; }

    /// <summary>
    /// Estado de la consecuencia.
    /// true = activo, false = inactivo.
    /// </summary>
    public bool Activo { get; set; }
}
