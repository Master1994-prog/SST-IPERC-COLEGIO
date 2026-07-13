using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para actualizar un peligro.
/// No contiene Id porque el Id llega desde la ruta.
/// Ejemplo: PUT /api/peligros/1
/// </summary>
public class UpdatePeligroDto
{
    /// <summary>
    /// Código actualizado del peligro.
    /// </summary>
    [Required]
    [MaxLength(20)]
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre actualizado del peligro.
    /// </summary>
    [Required]
    [MaxLength(200)]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción actualizada.
    /// </summary>
    [MaxLength(1500)]
    public string? Descripcion { get; set; }

    /// <summary>
    /// Id del tipo de peligro.
    /// </summary>
    [Required]
    public long TipoPeligroId { get; set; }

    /// <summary>
    /// Fuente que genera el peligro.
    /// </summary>
    [MaxLength(300)]
    public string? Fuente { get; set; }

    /// <summary>
    /// Medio por el cual se transmite.
    /// </summary>
    [MaxLength(300)]
    public string? Medio { get; set; }

    /// <summary>
    /// Persona o elemento expuesto.
    /// </summary>
    [MaxLength(300)]
    public string? Receptor { get; set; }

    /// <summary>
    /// Requisitos legales aplicables.
    /// </summary>
    [MaxLength(1000)]
    public string? RequisitoLegal { get; set; }

    /// <summary>
    /// Recomendaciones generales.
    /// </summary>
    [MaxLength(2000)]
    public string? Recomendaciones { get; set; }

    /// <summary>
    /// Estado del peligro.
    /// true = activo, false = inactivo.
    /// </summary>
    public bool Activo { get; set; }
}
