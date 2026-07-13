using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;

namespace SST.Domain.SST.Entities;

/// <summary>
/// Representa un tipo de Equipo de Protección Personal (EPP).
/// Permite clasificar los equipos utilizados dentro del Sistema SST.
/// </summary>
[Table("TiposEquipoProteccion")]
public class TipoEquipoProteccion : BaseAuditableEntity
{
    #region Información General

    /// <summary>
    /// Código único del tipo de EPP.
    /// Ejemplo:
    /// EPP-TIPO-001
    /// </summary>
    [Required]
    [MaxLength(20)]
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre del tipo de EPP.
    /// Ejemplo:
    /// Protección de Cabeza
    /// Protección Respiratoria
    /// Protección Visual
    /// </summary>
    [Required]
    [MaxLength(150)]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción del tipo de EPP.
    /// </summary>
    [MaxLength(1000)]
    public string? Descripcion { get; set; }

    #endregion

    #region Configuración

    /// <summary>
    /// Orden de visualización.
    /// </summary>
    public int Orden { get; set; }

    /// <summary>
    /// Indica si el registro está activo.
    /// </summary>
    public bool Activo { get; set; } = true;

    /// <summary>
    /// Indica si pertenece al catálogo global.
    /// </summary>
    public bool EsGlobal { get; set; } = true;

    /// <summary>
    /// Colegio propietario.
    /// Si es null, pertenece al catálogo general.
    /// </summary>
    public long? ColegioId { get; set; }

    #endregion

    #region Navegación

    /// <summary>
    /// Equipos pertenecientes a este tipo.
    /// </summary>
    public virtual ICollection<EquipoProteccion> EquiposProteccion { get; set; }
        = new List<EquipoProteccion>();

    #endregion

    #region Métodos de Dominio

    /// <summary>
    /// Activa el tipo de EPP.
    /// </summary>
    public void Activar()
    {
        Activo = true;
    }

    /// <summary>
    /// Desactiva el tipo de EPP.
    /// </summary>
    public void Desactivar()
    {
        Activo = false;
    }

    /// <summary>
    /// Cambia el orden de visualización.
    /// </summary>
    /// <param name="orden">Nuevo orden.</param>
    public void CambiarOrden(int orden)
    {
        Orden = orden;
    }

    /// <summary>
    /// Actualiza la descripción.
    /// </summary>
    /// <param name="descripcion">Nueva descripción.</param>
    public void ActualizarDescripcion(string? descripcion)
    {
        Descripcion = descripcion;
    }

    #endregion
}
