using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para actualizar una clasificación
/// de control existente.
///
/// El identificador no se incluye porque llega
/// mediante la ruta del endpoint.
/// </summary>
public class UpdateClasificacionControlDto
{
    /// <summary>
    /// Código actualizado de la clasificación.
    /// </summary>
    [Required(ErrorMessage = "El código es obligatorio.")]
    [MaxLength(
        20,
        ErrorMessage = "El código no puede superar los 20 caracteres."
    )]
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre actualizado de la clasificación.
    /// </summary>
    [Required(ErrorMessage = "El nombre es obligatorio.")]
    [MaxLength(
        150,
        ErrorMessage = "El nombre no puede superar los 150 caracteres."
    )]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción actualizada.
    /// </summary>
    [MaxLength(
        1000,
        ErrorMessage = "La descripción no puede superar los 1000 caracteres."
    )]
    public string? Descripcion { get; set; }

    /// <summary>
    /// Prioridad actualizada.
    ///
    /// Un número menor representa una prioridad mayor.
    /// </summary>
    [Range(
        0,
        int.MaxValue,
        ErrorMessage = "La prioridad no puede ser negativa."
    )]
    public int Prioridad { get; set; }

    /// <summary>
    /// Estado actualizado del registro.
    /// </summary>
    public bool Activo { get; set; }
}
