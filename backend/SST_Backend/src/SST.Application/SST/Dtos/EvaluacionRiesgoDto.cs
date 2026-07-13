namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para mostrar una evaluación de riesgo IPERC.
/// </summary>
public class EvaluacionRiesgoDto
{
    public long Id { get; set; }

    public long ProbabilidadId { get; set; }

    public long SeveridadId { get; set; }

    public long NivelRiesgoId { get; set; }

    public int Valor { get; set; }

    public bool EsAceptable { get; set; }

    public bool RequiereAccion { get; set; }

    public string? Observaciones { get; set; }
}
