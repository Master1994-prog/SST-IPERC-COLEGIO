namespace SST.Application.SST.Dtos;

/// <summary>
/// Representa un peligro evaluado dentro de una Matriz IPERC.
/// </summary>
public class DetalleIPERCDto
{
    public long Id { get; set; }

    public long MatrizIPERCId { get; set; }

    public string? MatrizIPERCCodigo { get; set; }

    public int Item { get; set; }

    public string Tarea { get; set; } = string.Empty;

    public long PeligroId { get; set; }

    public string? PeligroNombre { get; set; }

    public long ConsecuenciaId { get; set; }

    public string? ConsecuenciaNombre { get; set; }

    public string? DescripcionPeligro { get; set; }

    public long EvaluacionInicialId { get; set; }

    /// Información completa de la evaluación inicial.
    public EvaluacionDetalleIPERCDto? EvaluacionInicial { get; set; }

    public long? EvaluacionResidualId { get; set; }

    /// Información completa de la evaluación posterior a los controles.
    public EvaluacionDetalleIPERCDto? EvaluacionResidual { get; set; }

    public List<long> ControlIds { get; set; } = new();

    public List<long> EquipoProteccionIds { get; set; } = new();

    public long? ResponsableImplementacionId { get; set; }

    public DateTime? FechaCompromiso { get; set; }

    public DateTime? FechaImplementacion { get; set; }

    public int EstadoImplementacionId { get; set; }

    public string EstadoImplementacionNombre { get; set; } = string.Empty;
}

/// <summary>
/// Información visible de una evaluación de riesgo.
/// </summary>
public class EvaluacionDetalleIPERCDto
{
    public long Id { get; set; }

    public long ProbabilidadId { get; set; }

    public string ProbabilidadNombre { get; set; } = string.Empty;

    public int ValorProbabilidad { get; set; }

    public long SeveridadId { get; set; }

    public string SeveridadNombre { get; set; } = string.Empty;

    public int ValorSeveridad { get; set; }

    public long NivelRiesgoId { get; set; }

    public string NivelRiesgoNombre { get; set; } = string.Empty;

    public string Color { get; set; } = "#9E9E9E";

    public int ValorRiesgo { get; set; }

    public bool EsAceptable { get; set; }

    public bool RequiereAccion { get; set; }

    public string? Observaciones { get; set; }
}
