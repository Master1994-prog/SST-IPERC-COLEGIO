namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para mostrar la relación entre un peligro y una consecuencia.
/// </summary>
public class PeligroConsecuenciaDto
{
    /// <summary>
    /// Identificador único de la relación peligro-consecuencia.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Id del peligro asociado.
    /// </summary>
    public long PeligroId { get; set; }

    /// <summary>
    /// Nombre del peligro asociado.
    /// </summary>
    public string? PeligroNombre { get; set; }

    /// <summary>
    /// Id de la consecuencia asociada.
    /// </summary>
    public long ConsecuenciaId { get; set; }

    /// <summary>
    /// Nombre de la consecuencia asociada.
    /// </summary>
    public string? ConsecuenciaNombre { get; set; }

    /// <summary>
    /// Observaciones específicas de la relación.
    /// </summary>
    public string? Observaciones { get; set; }

    /// <summary>
    /// Indica si esta consecuencia es la principal para el peligro.
    /// </summary>
    public bool Principal { get; set; }

    /// <summary>
    /// Estado del registro.
    /// true = activo, false = inactivo.
    /// </summary>
    public bool Activo { get; set; }
}
