using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para registrar una nueva medida de control.
///
/// El código no se recibe desde Flutter porque será
/// generado automáticamente por el backend.
/// </summary>
public class CreateControlDto
{
    /// <summary>
    /// Nombre de la medida de control.
    /// </summary>
    [Required(ErrorMessage = "El nombre del control es obligatorio.")]
    [MaxLength(
        250,
        ErrorMessage = "El nombre no puede superar los 250 caracteres."
    )]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción detallada del control.
    /// </summary>
    [MaxLength(
        2000,
        ErrorMessage = "La descripción no puede superar los 2000 caracteres."
    )]
    public string? Descripcion { get; set; }

    /// <summary>
    /// Clasificación asociada al control.
    /// </summary>
    [Range(
        1,
        long.MaxValue,
        ErrorMessage = "La clasificación seleccionada no es válida."
    )]
    public long ClasificacionControlId { get; set; }

    /// <summary>
    /// Indica si el control estará activo.
    /// </summary>
    public bool Activo { get; set; } = true;

    /// <summary>
    /// Usuario que registra el control.
    /// </summary>
    [Range(
        1,
        long.MaxValue,
        ErrorMessage = "El usuario que registra no es válido."
    )]
    public long UsuarioRegistroId { get; set; }
}
