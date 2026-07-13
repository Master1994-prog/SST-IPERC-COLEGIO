using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using SST.Domain.Common;

namespace SST.Domain.IPERC.Entities;

/// <summary>
/// Representa la evaluación del riesgo obtenida
/// a partir de la Probabilidad y la Severidad.
/// </summary>
[Table("EvaluacionesRiesgo")]
public class EvaluacionRiesgo : BaseAuditableEntity
{
    #region Relaciones

    /// <summary>
    /// Probabilidad seleccionada.
    /// </summary>
    [Required]
    public long ProbabilidadId { get; set; }

    /// <summary>
    /// Severidad seleccionada.
    /// </summary>
    [Required]
    public long SeveridadId { get; set; }

    /// <summary>
    /// Nivel de riesgo obtenido.
    /// </summary>
    [Required]
    public long NivelRiesgoId { get; set; }

    #endregion

    #region Resultados

    /// <summary>
    /// Valor numérico del riesgo.
    /// Resultado:
    /// Probabilidad × Severidad
    /// </summary>
    public int Valor { get; private set; }

    /// <summary>
    /// Indica si el riesgo es aceptable.
    /// </summary>
    public bool EsAceptable { get; private set; }

    /// <summary>
    /// Requiere implementar medidas de control.
    /// </summary>
    public bool RequiereAccion { get; private set; }

    /// <summary>
    /// Observaciones del evaluador.
    /// </summary>
    [MaxLength(1000)]
    public string? Observaciones { get; set; }

    #endregion

    #region Navegación

    [ForeignKey(nameof(ProbabilidadId))]
    public virtual Probabilidad Probabilidad { get; set; } = null!;

    [ForeignKey(nameof(SeveridadId))]
    public virtual Severidad Severidad { get; set; } = null!;

    [ForeignKey(nameof(NivelRiesgoId))]
    public virtual NivelRiesgo NivelRiesgo { get; set; } = null!;

    #endregion

    #region Métodos

    /// <summary>
    /// Calcula el valor del riesgo.
    /// </summary>
    public void Calcular()
    {
        Valor = Probabilidad.Valor * Severidad.Valor;

        EsAceptable = NivelRiesgo.Aceptable;

        RequiereAccion = !EsAceptable;
    }

    /// <summary>
    /// Calcula el riesgo utilizando valores numéricos.
    /// </summary>
    /// <param name="probabilidad">Valor de probabilidad.</param>
    /// <param name="severidad">Valor de severidad.</param>
    public void Calcular(int probabilidad, int severidad)
    {
        Valor = probabilidad * severidad;
    }

    /// <summary>
    /// Asigna automáticamente el nivel de riesgo
    /// según el valor obtenido.
    /// </summary>
    public void AsignarNivel()
    {
        if (Valor <= 4)
        {
            EsAceptable = true;
            RequiereAccion = false;
            return;
        }

        if (Valor <= 9)
        {
            EsAceptable = true;
            RequiereAccion = false;
            return;
        }

        if (Valor <= 16)
        {
            EsAceptable = false;
            RequiereAccion = true;
            return;
        }

        EsAceptable = false;
        RequiereAccion = true;
    }

    /// <summary>
    /// Reinicia la evaluación.
    /// </summary>
    public void Reiniciar()
    {
        Valor = 0;
        EsAceptable = false;
        RequiereAccion = false;
        Observaciones = null;
    }

    #endregion
}