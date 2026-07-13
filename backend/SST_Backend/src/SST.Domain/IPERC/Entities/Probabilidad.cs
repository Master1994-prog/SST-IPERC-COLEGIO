using SST.Domain.Common;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SST.Domain.IPERC.Entities;

/// <summary>
/// Representa la probabilidad de ocurrencia de un peligro.
/// Se utiliza para calcular el nivel de riesgo.
/// </summary>
[Table("Probabilidades")]
public class Probabilidad : BaseAuditableEntity
{
    /// <summary>
    /// Valor numérico de la probabilidad.
    /// </summary>
    [Range(1, 5)]
    public int Valor { get; set; }

    /// <summary>
    /// Nombre de la probabilidad.
    /// Ejemplo:
    /// Rara
    /// Poco Probable
    /// Posible
    /// Probable
    /// Casi Segura
    /// </summary>
    [Required]
    [MaxLength(100)]
    public string Nombre { get; set; } = string.Empty;

    /// <summary>
    /// Descripción.
    /// </summary>
    [MaxLength(500)]
    public string? Descripcion { get; set; }

    /// <summary>
    /// Evaluaciones asociadas.
    /// </summary>
    public virtual ICollection<EvaluacionRiesgo> Evaluaciones { get; set; }
        = new List<EvaluacionRiesgo>();
}