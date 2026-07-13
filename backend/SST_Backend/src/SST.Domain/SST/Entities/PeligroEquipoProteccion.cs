using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;

namespace SST.Domain.SST.Entities;

/// <summary>
/// Relación entre un peligro y los equipos
/// de protección personal recomendados.
/// </summary>
[Table("PeligrosEquiposProteccion")]
public class PeligroEquipoProteccion : BaseAuditableEntity
{
    [Required]
    public long PeligroId { get; set; }

    [Required]
    public long EquipoProteccionId { get; set; }

    /// <summary>
    /// Indica si el EPP es obligatorio.
    /// </summary>
    public bool Obligatorio { get; set; }

    [ForeignKey(nameof(PeligroId))]
    public virtual Peligro Peligro { get; set; } = null!;

    [ForeignKey(nameof(EquipoProteccionId))]
    public virtual EquipoProteccion EquipoProteccion { get; set; } = null!;
}
