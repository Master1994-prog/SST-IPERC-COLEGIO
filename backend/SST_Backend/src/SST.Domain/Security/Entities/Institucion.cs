using SST.Domain.Common;
using SST.Domain.Organization.Entities;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SST.Domain.Security.Entities;

/// <summary>
/// Representa una institución educativa que utiliza el sistema SST-IPERC.
/// El sistema está preparado para administrar múltiples colegios.
/// </summary>
public class Institucion : BaseAuditableEntity
{
    
    [Required]
    [StringLength(200)]
    public string Nombre { get; set; } = string.Empty;

    [StringLength(11)]
    public string? Ruc { get; set; }

    [StringLength(20)]
    public string? CodigoModular { get; set; }

    [Required]
    [StringLength(250)]
    public string Direccion { get; set; } = string.Empty;

    [Required]
    [StringLength(100)]
    public string Departamento { get; set; } = string.Empty;

    [Required]
    [StringLength(100)]
    public string Provincia { get; set; } = string.Empty;

    [Required]
    [StringLength(100)]
    public string Distrito { get; set; } = string.Empty;

    [StringLength(20)]
    public string? Telefono { get; set; }

    [StringLength(150)]
    [EmailAddress]
    public string? Correo { get; set; }

    [StringLength(150)]
    public string? Director { get; set; }

    [StringLength(255)]
    public string? Logo { get; set; }

    // Relaciones

    [ForeignKey(nameof(UsuarioRegistroId))]
    public virtual Usuario? UsuarioRegistro { get; set; }

    [ForeignKey(nameof(UsuarioActualizacionId))]
    public virtual Usuario? UsuarioActualizacion { get; set; }

    public virtual ICollection<Sede> Sedes { get; set; } = new List<Sede>();

    public virtual ICollection<Usuario> Usuarios { get; set; } = new List<Usuario>();
}