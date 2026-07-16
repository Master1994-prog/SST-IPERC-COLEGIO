using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;

namespace SST.Domain.Security.Entities;

[Table("UsuariosRoles")]
public class UsuarioRol : BaseAuditableEntity
{
    public long UsuarioId { get; set; }

    public long RolId { get; set; }

    public bool Activo { get; set; } = true;

    public virtual Usuario Usuario { get; set; } = null!;

    public virtual Rol Rol { get; set; } = null!;
}
