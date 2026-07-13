using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;
using SST.Domain.IPERC.Entities;

namespace SST.Domain.SST.Entities;

/// <summary>
/// Representa un peligro identificado dentro del Sistema de
/// Seguridad y Salud en el Trabajo.
/// Un peligro puede utilizarse en múltiples matrices IPERC.
/// </summary>
[Table("Peligros")]
public class Peligro : BaseAuditableEntity
{
    #region Información General

    /// <summary>
    /// Código único del peligro.
    /// Ejemplo:
    /// PEL-0001
    /// </summary>
    [Required]
    [MaxLength(20)]
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre del peligro.
    /// Ejemplo:
    /// Piso Mojado
    /// Exposición a Ruido
    /// Trabajo en Altura
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
    /// Tipo de peligro.
    /// </summary>
    [Required]
    public long TipoPeligroId { get; set; }

    /// <summary>
    /// Fuente que genera el peligro.
    /// </summary>
    [MaxLength(300)]
    public string? Fuente { get; set; }

    /// <summary>
    /// Medio por el cual se transmite.
    /// </summary>
    [MaxLength(300)]
    public string? Medio { get; set; }

    /// <summary>
    /// Persona o elemento expuesto.
    /// </summary>
    [MaxLength(300)]
    public string? Receptor { get; set; }

    #endregion

    #region Gestión

    /// <summary>
    /// Requisitos legales aplicables.
    /// </summary>
    [MaxLength(1000)]
    public string? RequisitoLegal { get; set; }

    /// <summary>
    /// Recomendaciones generales.
    /// </summary>
    [MaxLength(2000)]
    public string? Recomendaciones { get; set; }

    /// <summary>
    /// Estado del peligro.
    /// </summary>
    public bool Activo { get; set; } = true;

    #endregion

    #region Navegación

    /// <summary>
    /// Tipo de peligro.
    /// </summary>
    [ForeignKey(nameof(TipoPeligroId))]
    public virtual TipoPeligro TipoPeligro { get; set; } = null!;

    /// <summary>
    /// Relación entre peligros y consecuencias.
    /// </summary>
    public virtual ICollection<PeligroConsecuencia> PeligroConsecuencias { get; set; }
        = new List<PeligroConsecuencia>();

    /// <summary>
    /// Detalles IPERC donde se utiliza este peligro.
    /// </summary>
    public virtual ICollection<DetalleIPERC> DetallesIPERC { get; set; }
        = new List<DetalleIPERC>();

    /// <summary>
    /// Controles recomendados para este peligro.
    /// </summary>
    public virtual ICollection<PeligroControl> PeligroControles { get; set; }
        = new List<PeligroControl>();

    /// <summary>
    /// Equipos de protección recomendados.
    /// </summary>
    public virtual ICollection<PeligroEquipoProteccion> PeligroEquiposProteccion { get; set; }
        = new List<PeligroEquipoProteccion>();

    #endregion

    #region Métodos de Dominio

    /// <summary>
    /// Activa el peligro.
    /// </summary>
    public void Activar()
    {
        Activo = true;
    }

    /// <summary>
    /// Desactiva el peligro.
    /// </summary>
    public void Desactivar()
    {
        Activo = false;
    }

    /// <summary>
    /// Actualiza la descripción.
    /// </summary>
    /// <param name="descripcion">Nueva descripción.</param>
    public void ActualizarDescripcion(string? descripcion)
    {
        Descripcion = descripcion;
    }

    /// <summary>
    /// Actualiza la recomendación.
    /// </summary>
    /// <param name="recomendacion">Nueva recomendación.</param>
    public void ActualizarRecomendacion(string? recomendacion)
    {
        Recomendaciones = recomendacion;
    }

    /// <summary>
    /// Actualiza el requisito legal.
    /// </summary>
    /// <param name="requisito">Nuevo requisito legal.</param>
    public void ActualizarRequisitoLegal(string? requisito)
    {
        RequisitoLegal = requisito;
    }

    #endregion
}