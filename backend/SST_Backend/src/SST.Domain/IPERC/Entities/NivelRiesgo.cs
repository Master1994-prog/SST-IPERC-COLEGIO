using SST.Domain.Common;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SST.Domain.IPERC.Entities;

/// <summary>
/// Nivel obtenido del cálculo del riesgo.
/// </summary>
[Table("NivelesRiesgo")]
public class NivelRiesgo : BaseAuditableEntity
{
    [Required]
    [MaxLength(80)]
    public string Nombre { get; set; } = string.Empty;

    public int Desde { get; set; }

    public int Hasta { get; set; }

    [MaxLength(20)]
    public string Color { get; set; } = string.Empty;

    public bool Aceptable { get; set; }

    public virtual ICollection<EvaluacionRiesgo> Evaluaciones { get; set; }
        = new List<EvaluacionRiesgo>();
}