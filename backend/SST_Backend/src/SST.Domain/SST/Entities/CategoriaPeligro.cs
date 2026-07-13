using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;

namespace SST.Domain.SST.Entities;

/// <summary>
/// Representa la categoría principal de un peligro.
/// Permite organizar los peligros según su naturaleza,
/// facilitando la identificación y gestión dentro del sistema SST.
/// </summary>
[Table("CategoriasPeligro")]
public class CategoriaPeligro : BaseAuditableEntity
{
    #region Información General

    /// <summary>
    /// Código único de la categoría.
    /// Ejemplo:
    /// CP-001
    /// BIO
    /// QUI
    /// </summary>
    [Required]
    [MaxLength(20)]
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre de la categoría.
    /// </summary>
    [Required]
    [MaxLength(150)]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción de la categoría.
    /// </summary>
    [MaxLength(1000)]
    public string? Descripcion { get; set; }

    /// <summary>
    /// Color utilizado en la interfaz.
    /// Formato hexadecimal (#FFFFFF).
    /// </summary>
    [MaxLength(10)]
    public string? Color { get; set; }

    /// <summary>
    /// Icono representativo.
    /// </summary>
    [MaxLength(100)]
    public string? Icono { get; set; }

    /// <summary>
    /// Orden de visualización.
    /// </summary>
    public int Orden { get; set; }

    /// <summary>
    /// Indica si la categoría está activa.
    /// </summary>
    public bool Activo { get; set; } = true;

    #endregion

    #region Navegación

    /// <summary>
    /// Tipos de peligro pertenecientes a la categoría.
    /// </summary>
    public virtual ICollection<TipoPeligro> TiposPeligro { get; set; }
        = new List<TipoPeligro>();

    #endregion

    #region Métodos de Dominio

    /// <summary>
    /// Activa la categoría.
    /// </summary>
    public void Activar()
    {
        Activo = true;
    }

    /// <summary>
    /// Desactiva la categoría.
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
    /// Actualiza el color de la categoría.
    /// </summary>
    /// <param name="color">Color hexadecimal.</param>
    public void CambiarColor(string color)
    {
        Color = color;
    }

    /// <summary>
    /// Actualiza el icono.
    /// </summary>
    /// <param name="icono">Nombre o ruta del icono.</param>
    public void CambiarIcono(string icono)
    {
        Icono = icono;
    }

    #endregion
}