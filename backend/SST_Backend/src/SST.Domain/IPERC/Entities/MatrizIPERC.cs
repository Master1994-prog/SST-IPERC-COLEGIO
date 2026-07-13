using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;
using SST.Domain.Organization.Entities;
using SST.Domain.Security.Entities;
using InstitucionOrg = global::SST.Domain.Organization.Entities.Institucion;

namespace SST.Domain.IPERC.Entities;

/// <summary>
/// Representa la cabecera de una Matriz IPERC.
/// Contiene la información general de una evaluación de riesgos
/// realizada sobre una actividad específica dentro de una institución.
/// </summary>
[Table("MatricesIPERC")]
public class MatrizIPERC : BaseAuditableEntity
{
    #region Información General

    /// <summary>
    /// Código único de la matriz.
    /// Ejemplo: IPERC-2026-0001
    /// </summary>
    [Required]
    [MaxLength(30)]
    public string Codigo { get; set; } = string.Empty;

    /// <summary>
    /// Nombre o título de la matriz.
    /// </summary>
    [Required]
    [MaxLength(250)]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Objetivo de la evaluación.
    /// </summary>
    [MaxLength(1000)]
    public string? Objetivo { get; set; }

    /// <summary>
    /// Alcance de la evaluación.
    /// </summary>
    [MaxLength(1000)]
    public string? Alcance { get; set; }

    /// <summary>
    /// Versión de la matriz.
    /// </summary>
    public int Version { get; set; } = 1;

    #endregion

    #region Fechas

    /// <summary>
    /// Fecha en que se realizó la evaluación.
    /// </summary>
    public DateTime FechaEvaluacion { get; set; }

    /// <summary>
    /// Fecha programada para revisión.
    /// </summary>
    public DateTime? FechaRevision { get; set; }

    /// <summary>
    /// Fecha de aprobación.
    /// </summary>
    public DateTime? FechaAprobacion { get; set; }

    #endregion

    #region Estado

    /// <summary>
    /// Estado de la matriz.
    /// Borrador
    /// En revisión
    /// Aprobada
    /// Cerrada
    /// </summary>
    [Required]
    [MaxLength(30)]
    public string EstadoMatriz { get; set; } = "Borrador";

    /// <summary>
    /// Observaciones generales.
    /// </summary>
    [MaxLength(3000)]
    public string? Observaciones { get; set; }

    #endregion

    #region Relaciones Organización

    /// <summary>
    /// Institución propietaria.
    /// </summary>
    public long InstitucionId { get; set; }

    /// <summary>
    /// Sede donde se realizó la evaluación.
    /// </summary>
    public long SedeId { get; set; }

    /// <summary>
    /// Área evaluada.
    /// </summary>
    public long AreaId { get; set; }

    /// <summary>
    /// Proceso evaluado.
    /// </summary>
    public long ProcesoId { get; set; }

    /// <summary>
    /// Actividad evaluada.
    /// </summary>
    public long ActividadId { get; set; }

    /// <summary>
    /// Puesto de trabajo evaluado.
    /// </summary>
    public long PuestoTrabajoId { get; set; }

    #endregion

    #region Relaciones Usuarios

    /// <summary>
    /// Responsable de la evaluación.
    /// </summary>
    public long ResponsableId { get; set; }

    /// <summary>
    /// Aprobador de la matriz.
    /// </summary>
    public long? AprobadorId { get; set; }

    #endregion

    #region Navegación

    [ForeignKey(nameof(InstitucionId))]
    public virtual InstitucionOrg Institucion { get; set; } = null!;

    [ForeignKey(nameof(SedeId))]
    public virtual Sede Sede { get; set; } = null!;

    [ForeignKey(nameof(AreaId))]
    public virtual Area Area { get; set; } = null!;

    [ForeignKey(nameof(ProcesoId))]
    public virtual Proceso Proceso { get; set; } = null!;

    [ForeignKey(nameof(ActividadId))]
    public virtual Actividad Actividad { get; set; } = null!;

    [ForeignKey(nameof(PuestoTrabajoId))]
    public virtual PuestoTrabajo PuestoTrabajo { get; set; } = null!;

    [ForeignKey(nameof(ResponsableId))]
    public virtual Usuario Responsable { get; set; } = null!;

    [ForeignKey(nameof(AprobadorId))]
    public virtual Usuario? Aprobador { get; set; }

    #endregion

    #region Relaciones IPERC

    /// <summary>
    /// Lista de peligros evaluados dentro de la matriz.
    /// </summary>
    public virtual ICollection<DetalleIPERC> Detalles { get; set; }
        = new List<DetalleIPERC>();

    #endregion
}
