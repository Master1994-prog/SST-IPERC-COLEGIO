using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;

namespace SST.Domain.SST.Entities;

/// <summary>
/// Representa un tipo de peligro perteneciente a una categoría.
/// Ejemplo:
/// Categoría: Físico
/// Tipo: Ruido
///
/// Categoría: Químico
/// Tipo: Gases
/// </summary>
[Table("TiposPeligro")]
public class TipoPeligro : BaseAuditableEntity
{
    #region Información General

    /// <summary>
    /// Código interno.
    /// Ejemplo:
    /// FIS-001
    /// QUI-003
    /// </summary>
    [Required]
    [MaxLength(20)]
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre del tipo de peligro.
    /// </summary>
    [Required]
    [MaxLength(150)]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción del tipo.
    /// </summary>
    [MaxLength(1000)]
    public string? Descripcion { get; set; }

    /// <summary>
    /// Orden de visualización.
    /// </summary>
    public int Orden { get; set; }

    /// <summary>
    /// Estado del registro.
    /// </summary>
    public bool Activo { get; set; } = true;

    #endregion

    #region Relaciones

    /// <summary>
    /// Categoría a la que pertenece.
    /// </summary>
    [Required]
    public long CategoriaPeligroId { get; set; }

    #endregion

    #region Navegación

    /// <summary>
    /// Categoría propietaria.
    /// </summary>
    [ForeignKey(nameof(CategoriaPeligroId))]
    public virtual CategoriaPeligro CategoriaPeligro { get; set; } = null!;

    /// <summary>
    /// Lista de peligros pertenecientes a este tipo.
    /// </summary>
    public virtual ICollection<Peligro> Peligros { get; set; }
        = new List<Peligro>();

    #endregion

    #region Métodos de Dominio

    /// <summary>
    /// Activa el tipo de peligro.
    /// </summary>
    public void Activar()
    {
        Activo = true;
    }

    /// <summary>
    /// Desactiva el tipo de peligro.
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