namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para mostrar la información de un detalle de Matriz IPERC.
/// Cada detalle representa un peligro evaluado dentro de una matriz.
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

    public long? EvaluacionResidualId { get; set; }

    public long? ResponsableImplementacionId { get; set; }

    public DateTime? FechaCompromiso { get; set; }

    public DateTime? FechaImplementacion { get; set; }

    public int EstadoImplementacionId { get; set; }

    public string EstadoImplementacionNombre { get; set; } = string.Empty;
}
