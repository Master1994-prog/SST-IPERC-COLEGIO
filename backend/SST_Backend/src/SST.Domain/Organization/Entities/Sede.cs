using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;

namespace SST.Domain.Organization.Entities;

[Table("Sedes")]
public class Sede : BaseAuditableEntity
{
    [Required]
    [MaxLength(150)]
    public string Nombre { get; set; } = string.Empty;

    [MaxLength(300)]
    public string? Direccion { get; set; }

    public bool Activo { get; set; } = true;

    public long InstitucionId { get; set; }

    [ForeignKey(nameof(InstitucionId))]
    public virtual Institucion Institucion { get; set; } = null!;
}