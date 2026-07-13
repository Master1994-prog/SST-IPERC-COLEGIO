using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;
using SST.Domain.IPERC.Entities;

namespace SST.Domain.SST.Entities;

/// <summary>
/// Representa un control para eliminar o reducir un riesgo.
/// Los controles pertenecen al catálogo SST y pueden ser
/// utilizados por múltiples peligros.
/// </summary>
[Table("Controles")]
public class Control : BaseAuditableEntity
{
    #region Información General

    /// <summary>
    /// Código único del control.
    /// Ejemplo:
    /// CTR-0001
    /// </summary>
    [Required]
    [MaxLength(20)]
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre del control.
    /// </summary>
    [Required]
    [MaxLength(250)]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción detallada.
    /// </summary>
    [MaxLength(2000)]
    public string? Descripcion { get; set; }

    #endregion

    #region Clasificación

    /// <summary>
    /// Clasificación del control.
    /// </summary>
    [Required]
    public long ClasificacionControlId { get; set; }

    /// <summary>
    /// Prioridad del control.
    /// </summary>
    public int Prioridad { get; set; }

    /// <summary>
    /// Indica si el control es obligatorio.
    /// </summary>
    public bool Obligatorio { get; set; }

    /// <summary>
    /// Frecuencia recomendada.
    /// </summary>
    [MaxLength(100)]
    public string? Frecuencia { get; set; }

    /// <summary>
    /// Responsable sugerido.
    /// </summary>
    [MaxLength(200)]
    public string? ResponsableSugerido { get; set; }

    /// <summary>
    /// Requisitos legales relacionados.
    /// </summary>
    [MaxLength(1000)]
    public string? RequisitoLegal { get; set; }

    #endregion

    #region Estado

    /// <summary>
    /// Indica si el control está activo.
    /// </summary>
    public bool Activo { get; set; } = true;

    #endregion

    #region Navegación

    /// <summary>
    /// Clasificación del control.
    /// </summary>
    [ForeignKey(nameof(ClasificacionControlId))]
    public virtual ClasificacionControl ClasificacionControl { get; set; } = null!;

    /// <summary>
    /// Relación entre peligros y controles.
    /// </summary>
    public virtual ICollection<PeligroControl> PeligroControles { get; set; }
        = new List<PeligroControl>();

    /// <summary>
    /// Relación entre controles y detalles IPERC.
    /// </summary>
    public virtual ICollection<DetalleIPERCControl> DetalleIPERCControles { get; set; }
        = new List<DetalleIPERCControl>();

    #endregion

    #region Métodos de Dominio

    /// <summary>
    /// Activa el control.
    /// </summary>
    public void Activar()
    {
        Activo = true;
    }

    /// <summary>
    /// Desactiva el control.
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

    /// <summary>
    /// Actualiza la frecuencia recomendada.
    /// </summary>
    public void ActualizarFrecuencia(string? frecuencia)
    {
        Frecuencia = frecuencia;
    }

    /// <summary>
    /// Actualiza el responsable sugerido.
    /// </summary>
    public void ActualizarResponsable(string? responsable)
    {
        ResponsableSugerido = responsable;
    }

    /// <summary>
    /// Marca el control como obligatorio.
    /// </summary>
    public void MarcarComoObligatorio()
    {
        Obligatorio = true;
    }

    /// <summary>
    /// Marca el control como opcional.
    /// </summary>
    public void MarcarComoOpcional()
    {
        Obligatorio = false;
    }

    /// <summary>
    /// Actualiza la descripción.
    /// </summary>
    public void ActualizarDescripcion(string? descripcion)
    {
        Descripcion = descripcion;
    }

    /// <summary>
    /// Actualiza el requisito legal.
    /// </summary>
    public void ActualizarRequisitoLegal(string? requisito)
    {
        RequisitoLegal = requisito;
    }

    #endregion

    /// <summary>
    /// Indica si el control pertenece al catálogo general.
    /// </summary>
    public bool EsGlobal { get; set; } = true;

    /// <summary>
    /// Colegio propietario del control.
    /// Si es nulo, el control es global.
    /// </summary>
    public long? ColegioId { get; set; }

}
