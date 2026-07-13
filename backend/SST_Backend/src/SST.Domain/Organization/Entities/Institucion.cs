using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;

namespace SST.Domain.Organization.Entities;

[Table("Instituciones")]
public class Institucion : BaseAuditableEntity
{
    #region Información General

    [Required]
    [MaxLength(20)]
    public string Codigo { get; set; } = string.Empty;

    [Required]
    [MaxLength(200)]
    public string Nombre { get; set; } = string.Empty;

    [MaxLength(20)]
    public string? Ruc { get; set; }

    [MaxLength(300)]
    public string? Direccion { get; set; }

    [MaxLength(100)]
    public string? Distrito { get; set; }

    [MaxLength(100)]
    public string? Provincia { get; set; }

    [MaxLength(100)]
    public string? Departamento { get; set; }

    [MaxLength(100)]
    public string? Telefono { get; set; }

    [MaxLength(150)]
    public string? Correo { get; set; }

    #endregion

    #region Gestión

    public bool Activo { get; set; } = true;

    #endregion

    #region Navegación

    public virtual ICollection<Sede> Sedes { get; set; }
        = new List<Sede>();

    public virtual ICollection<Area> Areas { get; set; }
        = new List<Area>();

    public virtual ICollection<Proceso> Procesos { get; set; }
        = new List<Proceso>();

    public virtual ICollection<Actividad> Actividades { get; set; }
        = new List<Actividad>();

    public virtual ICollection<PuestoTrabajo> PuestosTrabajo { get; set; }
        = new List<PuestoTrabajo>();

    #endregion

    #region Métodos de Dominio

    public void Activar()
    {
        Activo = true;
    }

    public void Desactivar()
    {
        Activo = false;
    }

    public void ActualizarDireccion(string? direccion)
    {
        Direccion = direccion;
    }

    public void ActualizarContacto(string? telefono, string? correo)
    {
        Telefono = telefono;
        Correo = correo;
    }

    #endregion
}
