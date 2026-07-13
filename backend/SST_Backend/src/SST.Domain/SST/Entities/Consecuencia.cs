using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;

namespace SST.Domain.SST.Entities;

/// <summary>
/// Representa una consecuencia o daño potencial
/// derivado de un peligro identificado.
/// Las consecuencias son reutilizables por diferentes peligros.
/// </summary>
[Table("Consecuencias")]
public class Consecuencia : BaseAuditableEntity
{
    #region Información General

    /// <summary>
    /// Código único.
    /// Ejemplo:
    /// CON-0001
    /// </summary>
    [Required]
    [MaxLength(20)]
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre de la consecuencia.
    /// Ejemplo:
    /// Fractura
    /// Quemadura
    /// Intoxicación
    /// </summary>
    [Required]
    [MaxLength(200)]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción detallada.
    /// </summary>
    [MaxLength(1500)]
    public string? Descripcion { get; set; }

    #endregion

    #region Clasificación

    /// <summary>
    /// Clasificación de la consecuencia.
    /// Ejemplo:
    /// Lesión
    /// Enfermedad Ocupacional
    /// Daño Material
    /// Impacto Ambiental
    /// </summary>
    [MaxLength(100)]
    public string? Clasificacion { get; set; }

    /// <summary>
    /// Indica si puede ocasionar incapacidad permanente.
    /// </summary>
    public bool IncapacidadPermanente { get; set; }

    /// <summary>
    /// Indica si puede ocasionar fatalidad.
    /// </summary>
    public bool Fatalidad { get; set; }

    #endregion

    #region Gestión

    /// <summary>
    /// Estado del registro.
    /// </summary>
    public bool Activo { get; set; } = true;

    #endregion

    #region Navegación

    /// <summary>
    /// Relación entre peligros y consecuencias.
    /// </summary>
    public virtual ICollection<PeligroConsecuencia> PeligroConsecuencias
    { get; set; } = new List<PeligroConsecuencia>();

    #endregion

    #region Métodos de Dominio

    /// <summary>
    /// Activa la consecuencia.
    /// </summary>
    public void Activar()
    {
        Activo = true;
    }

    /// <summary>
    /// Desactiva la consecuencia.
    /// </summary>
    public void Desactivar()
    {
        Activo = false;
    }

    /// <summary>
    /// Marca la consecuencia como fatal.
    /// </summary>
    public void MarcarComoFatal()
    {
        Fatalidad = true;
    }

    /// <summary>
    /// Marca la consecuencia como incapacitante.
    /// </summary>
    public void MarcarComoIncapacitante()
    {
        IncapacidadPermanente = true;
    }

    #endregion
}
