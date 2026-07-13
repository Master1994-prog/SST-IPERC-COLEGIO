using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para actualizar una relación entre peligro y control.
/// No contiene Id porque el Id llega desde la ruta.
/// </summary>
public class UpdatePeligroControlDto
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
    /// </summary>
    public int Prioridad { get; set; }

    /// <summary>
    /// Estado del registro.
    /// </summary>
    public bool Activo { get; set; }
}
