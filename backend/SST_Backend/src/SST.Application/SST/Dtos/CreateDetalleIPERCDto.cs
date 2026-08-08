using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para registrar un nuevo detalle dentro de una Matriz IPERC.
///
/// La evaluación inicial ya no se envía mediante EvaluacionInicialId.
/// El backend recibirá Probabilidad + Severidad, calculará el valor
/// del riesgo y creará automáticamente la EvaluacionRiesgo.
///
/// La evaluación residual es opcional.
/// </summary>
public class CreateDetalleIPERCDto
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
    /// Si se envía 0, el backend asignará automáticamente
    /// el siguiente número disponible.
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
    /// Descripción específica del peligro encontrado
    /// durante la evaluación.
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
    /// Probabilidad inicial seleccionada.
    /// Debe corresponder a un registro de Probabilidades.
    ///
    /// El valor esperado en la matriz 5x5 será de 1 a 5.
    /// </summary>
    [Required]
    [Range(
        1,
        long.MaxValue,
        ErrorMessage =
            "Debe seleccionar la probabilidad inicial.")]
    public long ProbabilidadInicialId { get; set; }

    /// <summary>
    /// Severidad inicial seleccionada.
    /// Debe corresponder a un registro de Severidades.
    ///
    /// El valor esperado en la matriz 5x5 será de 1 a 5.
    /// </summary>
    [Required]
    [Range(
        1,
        long.MaxValue,
        ErrorMessage =
            "Debe seleccionar la severidad inicial.")]
    public long SeveridadInicialId { get; set; }

    /// <summary>
    /// Observaciones relacionadas con la evaluación inicial.
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
    /// Probabilidad residual después de aplicar controles.
    ///
    /// Es opcional.
    /// Si se proporciona, también debe enviarse SeveridadResidualId.
    /// </summary>
    public long? ProbabilidadResidualId { get; set; }

    /// <summary>
    /// Severidad residual después de aplicar controles.
    ///
    /// Es opcional.
    /// Si se proporciona, también debe enviarse ProbabilidadResidualId.
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
    /// Identificadores de los controles aplicados.
    ///
    /// Ejemplo:
    /// [1, 4, 7]
    /// </summary>
    public List<long> ControlIds { get; set; } =
        new();

    // ============================================================
    // EQUIPOS DE PROTECCIÓN PERSONAL
    // ============================================================

    /// <summary>
    /// Identificadores de los EPP requeridos.
    ///
    /// Ejemplo:
    /// [2, 5]
    /// </summary>
    public List<long> EquipoProteccionIds { get; set; } =
        new();

    // ============================================================
    // IMPLEMENTACIÓN DE CONTROLES
    // ============================================================

    /// <summary>
    /// Usuario responsable de implementar las medidas.
    /// Es opcional al momento de crear el detalle.
    /// </summary>
    public long? ResponsableImplementacionId { get; set; }

    /// <summary>
    /// Fecha comprometida para implementar los controles.
    /// </summary>
    public DateTime? FechaCompromiso { get; set; }

    /// <summary>
    /// Fecha real de implementación.
    /// Normalmente será nula cuando recién se crea el detalle.
    /// </summary>
    public DateTime? FechaImplementacion { get; set; }

    // ============================================================
    // ESTADO DE IMPLEMENTACIÓN
    // ============================================================

    /// <summary>
    /// Estado de implementación:
    ///
    /// 0 = Pendiente
    /// 1 = EnProceso
    /// 2 = Implementado
    /// 3 = Verificado
    /// 4 = Cerrado
    /// </summary>
    [Range(
        0,
        4,
        ErrorMessage =
            "El estado de implementación debe estar entre 0 y 4.")]
    public int EstadoImplementacion { get; set; } =
        0;
}