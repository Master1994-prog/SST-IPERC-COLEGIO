using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;

namespace SST.Domain.Organization.Entities;

[Table("Areas")]
public class Area : BaseAuditableEntity
{
    [Required]
    [MaxLength(150)]
    public string Nombre { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? Descripcion { get; set; }

    public bool Activo { get; set; } = true;

    public long InstitucionId { get; set; }

    [ForeignKey(nameof(InstitucionId))]
    public virtual Institucion Institucion { get; set; } = null!;

    public virtual ICollection<Proceso> Procesos { get; set; }
        = new List<Proceso>();

    public virtual ICollection<PuestoTrabajo> PuestosTrabajo { get; set; }
        = new List<PuestoTrabajo>();
}