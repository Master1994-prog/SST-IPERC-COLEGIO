using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;

namespace SST.Domain.Organization.Entities;

/// <summary>
/// Representa un puesto de trabajo dentro del colegio.
/// </summary>
[Table("PuestosTrabajo")]
public class PuestoTrabajo : BaseAuditableEntity
{
    #region Información General

    /// <summary>
    /// Nombre del puesto de trabajo.
    /// Ejemplo: Secretaria, Director, Auxiliar administrativo.
    /// </summary>
    [Required]
    [MaxLength(150)]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción del puesto.
    /// </summary>
    [MaxLength(1000)]
    public string? Descripcion { get; set; }

    /// <summary>
    /// Estado del puesto.
    /// </summary>
    public bool Activo { get; set; } = true;

    #endregion

    #region Relaciones

    /// <summary>
    /// Área a la que pertenece el puesto de trabajo.
    /// </summary>
    public long AreaId { get; set; }

    #endregion

    #region Navegación

    /// <summary>
    /// Área relacionada.
    /// </summary>
    [ForeignKey(nameof(AreaId))]
    public virtual Area Area { get; set; } = null!;

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

    public void ActualizarDescripcion(string? descripcion)
    {
        Descripcion = descripcion;
    }

    #endregion
}