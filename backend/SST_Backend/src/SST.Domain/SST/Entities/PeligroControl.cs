using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;

namespace SST.Domain.SST.Entities;

/// <summary>
/// Relación entre un peligro y los controles
/// recomendados para mitigarlo.
/// </summary>
[Table("PeligrosControles")]
public class PeligroControl : BaseAuditableEntity
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
    /// true = activo, false = inactivo.
    /// </summary>
    public bool Activo { get; set; } = true;

    [ForeignKey(nameof(PeligroId))]
    public virtual Peligro Peligro { get; set; } = null!;

    [ForeignKey(nameof(ControlId))]
    public virtual Control Control { get; set; } = null!;
}
