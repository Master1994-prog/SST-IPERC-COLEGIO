using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para actualizar una evaluación de riesgo.
/// No contiene Id porque el Id llega desde la ruta.
/// </summary>
public class UpdateEvaluacionRiesgoDto
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
