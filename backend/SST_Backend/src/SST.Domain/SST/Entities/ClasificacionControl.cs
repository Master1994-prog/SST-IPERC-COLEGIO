using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;

namespace SST.Domain.SST.Entities;

/// <summary>
/// Representa la clasificación de un control según la
/// jerarquía de controles de SST.
/// </summary>
[Table("ClasificacionesControl")]
public class ClasificacionControl : BaseAuditableEntity
{
    #region Información General

    /// <summary>
    /// Código único.
    /// Ejemplo:
    /// JC-001
    /// </summary>
    [Required]
    [MaxLength(20)]
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre de la clasificación.
    /// </summary>
    [Required]
    [MaxLength(150)]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción.
    /// </summary>
    [MaxLength(1000)]
    public string? Descripcion { get; set; }

    /// <summary>
    /// Nivel de prioridad.
    /// Menor número = mayor prioridad.
    /// </summary>
    public int Prioridad { get; set; }

    /// <summary>
    /// Estado del registro.
    /// </summary>
    public bool Activo { get; set; } = true;

    #endregion

    #region Navegación

    /// <summary>
    /// Controles pertenecientes a esta clasificación.
    /// </summary>
    public virtual ICollection<Control> Controles { get; set; }
        = new List<Control>();

    #endregion

    #region Métodos de Dominio

    /// <summary>
    /// Activa la clasificación.
    /// </summary>
    public void Activar()
    {
        Activo = true;
    }

    /// <summary>
    /// Desactiva la clasificación.
    /// </summary>
    public void Desactivar()
    {
        Activo = false;
    }

    /// <summary>
    /// Cambia la prioridad.
    /// </summary>
    public void CambiarPrioridad(int prioridad)
    {
        Prioridad = prioridad;
    }

    #endregion
}
