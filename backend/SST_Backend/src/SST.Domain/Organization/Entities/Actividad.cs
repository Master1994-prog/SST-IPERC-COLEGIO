using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;

namespace SST.Domain.Organization.Entities;

[Table("Actividades")]
public class Actividad : BaseAuditableEntity
{
    [Required]
    [MaxLength(150)]
    public string Nombre { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? Descripcion { get; set; }

    public bool Activo { get; set; } = true;

    public long ProcesoId { get; set; }

    [ForeignKey(nameof(ProcesoId))]
    public virtual Proceso Proceso { get; set; } = null!;
}