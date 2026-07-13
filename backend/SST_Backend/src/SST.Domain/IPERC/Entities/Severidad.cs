using SST.Domain.Common;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SST.Domain.IPERC.Entities;

/// <summary>
/// Nivel de severidad del daño.
/// </summary>
[Table("Severidades")]
public class Severidad : BaseAuditableEntity
{
    [Range(1, 5)]
    public int Valor { get; set; }

    [Required]
    [MaxLength(100)]
    public string Nombre { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? Descripcion { get; set; }

    public virtual ICollection<EvaluacionRiesgo> Evaluaciones { get; set; }
        = new List<EvaluacionRiesgo>();
}