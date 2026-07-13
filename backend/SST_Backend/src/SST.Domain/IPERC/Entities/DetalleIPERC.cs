using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;
using SST.Domain.IPERC.Enums;
using SST.Domain.Security.Entities;
using SST.Domain.SST.Entities;

namespace SST.Domain.IPERC.Entities;

/// <summary>
/// Representa el detalle de una Matriz IPERC.
/// Cada registro corresponde a un peligro identificado
/// durante la evaluación de una actividad.
/// </summary>
[Table("DetalleIPERC")]
public class DetalleIPERC : BaseAuditableEntity
{
    #region Relación Principal

    /// <summary>
    /// Matriz IPERC a la que pertenece este registro.
    /// </summary>
    [Required]
    public long MatrizIPERCId { get; set; }

    #endregion

    #region Información General

    /// <summary>
    /// Número correlativo dentro de la matriz.
    /// </summary>
    public int Item { get; set; }

    /// <summary>
    /// Nombre de la tarea evaluada.
    /// Ejemplo:
    /// - Programación
    /// - Inspección
    /// - Revisión
    /// - Limpieza
    /// </summary>
    [Required]
    [MaxLength(250)]
    public string Tarea { get; set; } = string.Empty;

    #endregion

    #region Información del Peligro

    /// <summary>
    /// Peligro identificado.
    /// </summary>
    [Required]
    public long PeligroId { get; set; }

    /// <summary>
    /// Consecuencia o daño potencial.
    /// </summary>
    [Required]
    public long ConsecuenciaId { get; set; }

    /// <summary>
    /// Descripción específica del peligro encontrado.
    /// </summary>
    [MaxLength(1000)]
    public string? DescripcionPeligro { get; set; }

    #endregion

    #region Evaluaciones

    /// <summary>
    /// Evaluación inicial del riesgo.
    /// </summary>
    [Required]
    public long EvaluacionInicialId { get; set; }

    /// <summary>
    /// Evaluación residual luego de implementar controles.
    /// </summary>
    public long? EvaluacionResidualId { get; set; }

    #endregion

    #region Implementación

    /// <summary>
    /// Responsable de implementar las medidas de control.
    /// </summary>
    public long? ResponsableImplementacionId { get; set; }

    /// <summary>
    /// Fecha comprometida para implementar las medidas.
    /// </summary>
    public DateTime? FechaCompromiso { get; set; }

    /// <summary>
    /// Fecha real de implementación.
    /// </summary>
    public DateTime? FechaImplementacion { get; set; }

    /// <summary>
    /// Estado actual de implementación.
    /// </summary>
    public EstadoImplementacion EstadoImplementacion { get; set; }
        = EstadoImplementacion.Pendiente;

    #endregion

    #region Navegación

    /// <summary>
    /// Matriz propietaria.
    /// </summary>
    [ForeignKey(nameof(MatrizIPERCId))]
    public virtual MatrizIPERC MatrizIPERC { get; set; } = null!;

    /// <summary>
    /// Peligro identificado.
    /// </summary>
    [ForeignKey(nameof(PeligroId))]
    public virtual Peligro Peligro { get; set; } = null!;

    /// <summary>
    /// Consecuencia asociada.
    /// </summary>
    [ForeignKey(nameof(ConsecuenciaId))]
    public virtual Consecuencia Consecuencia { get; set; } = null!;

    /// <summary>
    /// Evaluación inicial.
    /// </summary>
    [ForeignKey(nameof(EvaluacionInicialId))]
    public virtual EvaluacionRiesgo EvaluacionInicial { get; set; } = null!;

    /// <summary>
    /// Evaluación residual.
    /// </summary>
    [ForeignKey(nameof(EvaluacionResidualId))]
    public virtual EvaluacionRiesgo? EvaluacionResidual { get; set; }

    /// <summary>
    /// Responsable de implementar las medidas.
    /// </summary>
    [ForeignKey(nameof(ResponsableImplementacionId))]
    public virtual Usuario? ResponsableImplementacion { get; set; }

    #endregion

    #region Relaciones

    /// <summary>
    /// Controles aplicados al peligro.
    /// </summary>
    public virtual ICollection<DetalleIPERCControl> Controles { get; set; }
        = new List<DetalleIPERCControl>();

    /// <summary>
    /// Equipos de Protección Personal requeridos.
    /// </summary>
    public virtual ICollection<DetalleIPERCEPP> EquiposProteccion { get; set; }
        = new List<DetalleIPERCEPP>();

    /// <summary>
    /// Seguimientos realizados sobre este peligro.
    /// </summary>
    public virtual ICollection<SeguimientoIPERC> Seguimientos { get; set; }
        = new List<SeguimientoIPERC>();

    #endregion

    #region Métodos de Dominio

    /// <summary>
    /// Marca las medidas como implementadas.
    /// </summary>
    public void MarcarComoImplementado()
    {
        EstadoImplementacion = EstadoImplementacion.Implementado;
        FechaImplementacion = DateTime.UtcNow;
    }

    /// <summary>
    /// Marca las medidas como verificadas.
    /// </summary>
    public void MarcarComoVerificado()
    {
        EstadoImplementacion = EstadoImplementacion.Verificado;
    }

    /// <summary>
    /// Cierra definitivamente el registro.
    /// </summary>
    public void Cerrar()
    {
        EstadoImplementacion = EstadoImplementacion.Cerrado;
    }

    /// <summary>
    /// Reabre el registro para una nueva implementación.
    /// </summary>
    public void Reabrir()
    {
        EstadoImplementacion = EstadoImplementacion.EnProceso;
    }

    #endregion
}
