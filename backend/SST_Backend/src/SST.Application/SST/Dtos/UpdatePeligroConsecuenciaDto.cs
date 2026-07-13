using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para actualizar una relación entre peligro y consecuencia.
/// No contiene Id porque el Id llega desde la ruta.
/// </summary>
public class UpdatePeligroConsecuenciaDto
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
    /// Observaciones específicas.
    /// </summary>
    [MaxLength(1000)]
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
