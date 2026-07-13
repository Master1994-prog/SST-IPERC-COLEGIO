using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;

namespace SST.Domain.Organization.Entities;

[Table("Procesos")]
public class Proceso : BaseAuditableEntity
{
    [Required]
    [MaxLength(150)]
    public string Nombre { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? Descripcion { get; set; }

    public bool Activo { get; set; } = true;

    public long AreaId { get; set; }

    [ForeignKey(nameof(AreaId))]
    public virtual Area Area { get; set; } = null!;

    public virtual ICollection<Actividad> Actividades { get; set; }
        = new List<Actividad>();
}