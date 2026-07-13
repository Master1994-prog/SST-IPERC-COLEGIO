namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para mostrar la relación entre un peligro y un control.
/// </summary>
public class PeligroControlDto
{
    public long Id { get; set; }

    public long PeligroId { get; set; }

    public string? PeligroNombre { get; set; }

    public long ControlId { get; set; }

    public string? ControlNombre { get; set; }

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
