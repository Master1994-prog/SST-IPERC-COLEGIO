using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para actualizar un detalle existente
/// dentro de una Matriz IPERC.
///
/// La evaluación inicial y residual se actualizan
/// mediante Probabilidad + Severidad.
/// El backend recalculará automáticamente:
///
/// Riesgo = Probabilidad × Severidad
///
/// y determinará el NivelRiesgo correspondiente.
/// </summary>
public class UpdateDetalleIPERCDto
{
    // ============================================================
    // MATRIZ
    // ============================================================

    [Required]
    [Range(
        1,
        long.MaxValue,
        ErrorMessage =
            "Debe seleccionar una Matriz IPERC válida.")]
    public long MatrizIPERCId { get; set; }

    /// <summary>
    /// Número correlativo dentro de la matriz.
    ///
    /// Si se envía 0, se conserva el número actual.
    /// </summary>
    [Range(
        0,
        int.MaxValue,
        ErrorMessage =
            "El número de item no puede ser negativo.")]
    public int Item { get; set; }

    // ============================================================
    // TAREA
    // ============================================================

    [Required(
        ErrorMessage =
            "La tarea es obligatoria.")]
    [StringLength(
        250,
        MinimumLength = 2,
        ErrorMessage =
            "La tarea debe tener entre 2 y 250 caracteres.")]
    public string Tarea { get; set; } =
        string.Empty;

    // ============================================================
    // PELIGRO
    // ============================================================

    [Required]
    [Range(
        1,
        long.MaxValue,
        ErrorMessage =
            "Debe seleccionar un peligro válido.")]
    public long PeligroId { get; set; }

    [Required]
    [Range(
        1,
        long.MaxValue,
        ErrorMessage =
            "Debe seleccionar una consecuencia válida.")]
    public long ConsecuenciaId { get; set; }

    /// <summary>
    /// Descripción específica del peligro identificado.
    /// </summary>
    [StringLength(
        1000,
        ErrorMessage =
            "La descripción del peligro no puede superar los 1000 caracteres.")]
    public string? DescripcionPeligro { get; set; }

    // ============================================================
    // EVALUACIÓN INICIAL
    // ============================================================

    /// <summary>
    /// Probabilidad inicial.
    /// </summary>
    [Required]
    [Range(
        1,
        long.MaxValue,
        ErrorMessage =
            "Debe seleccionar la probabilidad inicial.")]
    public long ProbabilidadInicialId { get; set; }

    /// <summary>
    /// Severidad inicial.
    /// </summary>
    [Required]
    [Range(
        1,
        long.MaxValue,
        ErrorMessage =
            "Debe seleccionar la severidad inicial.")]
    public long SeveridadInicialId { get; set; }

    /// <summary>
    /// Observaciones de la evaluación inicial.
    /// </summary>
    [StringLength(
        1000,
        ErrorMessage =
            "Las observaciones iniciales no pueden superar los 1000 caracteres.")]
    public string? ObservacionesEvaluacionInicial { get; set; }

    // ============================================================
    // EVALUACIÓN RESIDUAL
    // ============================================================

    /// <summary>
    /// Probabilidad residual.
    ///
    /// Es opcional.
    /// Si se proporciona también debe enviarse SeveridadResidualId.
    /// </summary>
    public long? ProbabilidadResidualId { get; set; }

    /// <summary>
    /// Severidad residual.
    ///
    /// Es opcional.
    /// Si se proporciona también debe enviarse ProbabilidadResidualId.
    /// </summary>
    public long? SeveridadResidualId { get; set; }

    /// <summary>
    /// Observaciones de la evaluación residual.
    /// </summary>
    [StringLength(
        1000,
        ErrorMessage =
            "Las observaciones residuales no pueden superar los 1000 caracteres.")]
    public string? ObservacionesEvaluacionResidual { get; set; }

    // ============================================================
    // CONTROLES
    // ============================================================

    /// <summary>
    /// Controles aplicados al detalle.
    /// </summary>
    public List<long> ControlIds { get; set; } =
        new();

    // ============================================================
    // EQUIPOS DE PROTECCIÓN PERSONAL
    // ============================================================

    /// <summary>
    /// EPP requeridos para el detalle.
    /// </summary>
    public List<long> EquipoProteccionIds { get; set; } =
        new();

    // ============================================================
    // IMPLEMENTACIÓN
    // ============================================================

    /// <summary>
    /// Usuario responsable de implementar los controles.
    /// </summary>
    public long? ResponsableImplementacionId { get; set; }

    /// <summary>
    /// Fecha comprometida para implementar los controles.
    /// </summary>
    public DateTime? FechaCompromiso { get; set; }

    /// <summary>
    /// Fecha real de implementación.
    /// </summary>
    public DateTime? FechaImplementacion { get; set; }

    // ============================================================
    // ESTADO
    // ============================================================

    /// <summary>
    /// Estado de implementación:
    ///
    /// 1 = Pendiente
    /// 2 = EnProceso
    /// 3 = Implementado
    /// 4 = Verificado
    /// 5 = Cerrado
    /// </summary>
    [Range(
        1,
        5,
        ErrorMessage =
            "El estado de implementación debe estar entre 1 y 5.")]
    public int EstadoImplementacion { get; set; } =
        1;
}
