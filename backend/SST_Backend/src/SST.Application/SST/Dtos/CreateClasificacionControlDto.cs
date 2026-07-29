using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para registrar una nueva clasificación
/// de control dentro de la jerarquía de controles SST.
/// </summary>
public class CreateClasificacionControlDto
{
    /// <summary>
    /// Código único de la clasificación.
    ///
    /// Ejemplo:
    /// JC-001
    /// </summary>
    [Required(ErrorMessage = "El código es obligatorio.")]
    [MaxLength(
        20,
        ErrorMessage = "El código no puede superar los 20 caracteres."
    )]
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre de la clasificación.
    ///
    /// Ejemplos:
    /// - Eliminación.
    /// - Sustitución.
    /// - Controles de ingeniería.
    /// - Controles administrativos.
    /// - Equipos de protección personal.
    /// </summary>
    [Required(ErrorMessage = "El nombre es obligatorio.")]
    [MaxLength(
        150,
        ErrorMessage = "El nombre no puede superar los 150 caracteres."
    )]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción de la clasificación.
    /// </summary>
    [MaxLength(
        1000,
        ErrorMessage = "La descripción no puede superar los 1000 caracteres."
    )]
    public string? Descripcion { get; set; }

    /// <summary>
    /// Nivel de prioridad.
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
    /// Indica si la clasificación estará activa.
    /// </summary>
    public bool Activo { get; set; } = true;
}
