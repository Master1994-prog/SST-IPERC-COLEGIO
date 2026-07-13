using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para registrar una evaluación de riesgo.
/// </summary>
public class CreateEvaluacionRiesgoDto
{
    [Required]
    public long ProbabilidadId { get; set; }

    [Required]
    public long SeveridadId { get; set; }

    [Required]
    public long NivelRiesgoId { get; set; }

    [MaxLength(1000)]
    public string? Observaciones { get; set; }
}
