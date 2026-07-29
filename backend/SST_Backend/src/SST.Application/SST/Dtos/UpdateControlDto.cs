using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para actualizar una medida de control.
///
/// El identificador del control llega desde:
/// PUT /api/controles/{id}
/// </summary>
public class UpdateControlDto
{
    /// <summary>
    /// Código actual del control.
    /// </summary>
    [Required(ErrorMessage = "El código del control es obligatorio.")]
    [MaxLength(
        20,
        ErrorMessage = "El código no puede superar los 20 caracteres."
    )]
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre actualizado del control.
    /// </summary>
    [Required(ErrorMessage = "El nombre del control es obligatorio.")]
    [MaxLength(
        250,
        ErrorMessage = "El nombre no puede superar los 250 caracteres."
    )]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción actualizada.
    /// </summary>
    [MaxLength(
        2000,
        ErrorMessage = "La descripción no puede superar los 2000 caracteres."
    )]
    public string? Descripcion { get; set; }

    /// <summary>
    /// Clasificación seleccionada.
    /// </summary>
    [Range(
        1,
        long.MaxValue,
        ErrorMessage = "La clasificación seleccionada no es válida."
    )]
    public long ClasificacionControlId { get; set; }

    /// <summary>
    /// Estado activo del control.
    /// </summary>
    public bool Activo { get; set; }

    /// <summary>
    /// Usuario que realiza la actualización.
    /// </summary>
    [Range(
        1,
        long.MaxValue,
        ErrorMessage = "El usuario que actualiza no es válido."
    )]
    public long UsuarioActualizacionId { get; set; }
}
