namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para mostrar la información de una Matriz IPERC.
/// El código se muestra, pero se genera automáticamente desde el backend.
/// </summary>
public class MatrizIPERCDto
{
    public long Id { get; set; }

    /// <summary>
    /// Código automático de la matriz IPERC.
    /// Ejemplo: IPERC-2026-0001.
    /// </summary>
    public string Codigo { get; set; } = string.Empty;

    public string Nombre { get; set; } = string.Empty;

    public string? Objetivo { get; set; }

    public string? Alcance { get; set; }

    public int Version { get; set; }

    public DateTime FechaEvaluacion { get; set; }

    public DateTime? FechaRevision { get; set; }

    public DateTime? FechaAprobacion { get; set; }

    public string EstadoMatriz { get; set; } = string.Empty;

    public string? Observaciones { get; set; }

    public long InstitucionId { get; set; }

    public long SedeId { get; set; }

    public long AreaId { get; set; }

    public long ProcesoId { get; set; }

    public long ActividadId { get; set; }

    public long PuestoTrabajoId { get; set; }

    public long ResponsableId { get; set; }

    public long? AprobadorId { get; set; }
}
