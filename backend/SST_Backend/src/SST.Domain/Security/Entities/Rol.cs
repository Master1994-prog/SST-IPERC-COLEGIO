using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;

namespace SST.Domain.Security.Entities;

[Table("Roles")]
public class Rol : BaseAuditableEntity
{
    [Required]
    [MaxLength(50)]
    public string Codigo { get; set; } = string.Empty;

    [Required]
    [MaxLength(100)]
    public string Nombre { get; set; } = string.Empty;

    [MaxLength(300)]
    public string? Descripcion { get; set; }

    public bool Activo { get; set; } = true;

    /// <summary>
    /// Indica si el rol tiene alcance sobre todas las instituciones.
    /// </summary>
    public bool EsGlobal { get; set; } = false;

    public virtual ICollection<UsuarioRol> UsuariosRoles { get; set; }
        = new List<UsuarioRol>();
}
