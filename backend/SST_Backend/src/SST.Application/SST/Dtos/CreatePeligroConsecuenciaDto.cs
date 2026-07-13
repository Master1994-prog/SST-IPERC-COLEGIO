using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para registrar una relación entre peligro y consecuencia.
/// </summary>
public class CreatePeligroConsecuenciaDto
{
    /// <summary>
    /// Id del peligro asociado.
    /// </summary>
    [Required]
    public long PeligroId { get; set; }

    /// <summary>
    /// Id de la consecuencia asociada.
    /// </summary>
    [Required]
    public long ConsecuenciaId { get; set; }

    /// <summary>
    /// Observaciones específicas sobre la consecuencia del peligro.
    /// </summary>
    [MaxLength(1000)]
    public string? Observaciones { get; set; }

    /// <summary>
    /// Indica si esta consecuencia será marcada como principal para el peligro.
    /// </summary>
    public bool Principal { get; set; }
}
