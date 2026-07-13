using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para registrar una relación entre peligro y control.
/// </summary>
public class CreatePeligroControlDto
{
    [Required]
    public long PeligroId { get; set; }

    [Required]
    public long ControlId { get; set; }

    /// <summary>
    /// Indica si el control es obligatorio.
    /// </summary>
    public bool Obligatorio { get; set; }

    /// <summary>
    /// Prioridad del control.
    /// 1 = mayor prioridad.
    /// </summary>
    public int Prioridad { get; set; }
}
