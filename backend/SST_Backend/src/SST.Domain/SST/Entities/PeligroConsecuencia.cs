using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;

namespace SST.Domain.SST.Entities;

/// <summary>
/// Relación entre un peligro y las consecuencias
/// que puede producir.
/// </summary>
[Table("PeligrosConsecuencias")]
public class PeligroConsecuencia : BaseAuditableEntity
{
    #region Relaciones

    /// <summary>
    /// Peligro asociado.
    /// </summary>
    [Required]
    public long PeligroId { get; set; }

    /// <summary>
    /// Consecuencia asociada.
    /// </summary>
    [Required]
    public long ConsecuenciaId { get; set; }

    #endregion

    #region Información

    /// <summary>
    /// Observaciones específicas.
    /// </summary>
    [MaxLength(1000)]
    public string? Observaciones { get; set; }

    /// <summary>
    /// Indica si esta consecuencia es la principal
    /// para este peligro.
    /// </summary>
    public bool Principal { get; set; }

    /// <summary>
    /// Estado del registro.
    /// true = activo, false = inactivo.
    /// </summary>
    public bool Activo { get; set; } = true;

    #endregion

    #region Navegación

    [ForeignKey(nameof(PeligroId))]
    public virtual Peligro Peligro { get; set; } = null!;

    [ForeignKey(nameof(ConsecuenciaId))]
    public virtual Consecuencia Consecuencia { get; set; } = null!;

    #endregion
}
