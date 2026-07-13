using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para actualizar una Matriz IPERC.
/// No contiene Codigo porque el código es automático y no debe editarse.
/// No contiene Id porque el Id llega desde la ruta.
/// </summary>
public class UpdateMatrizIPERCDto
{
    [Required]
    [MaxLength(250)]
    public string Nombre { get; set; } = string.Empty;

    [MaxLength(1000)]
    public string? Objetivo { get; set; }

    [MaxLength(1000)]
    public string? Alcance { get; set; }

    public int Version { get; set; }

    public DateTime FechaEvaluacion { get; set; }

    public DateTime? FechaRevision { get; set; }

    public DateTime? FechaAprobacion { get; set; }

    [Required]
    [MaxLength(30)]
    public string EstadoMatriz { get; set; } = "Borrador";

    [MaxLength(3000)]
    public string? Observaciones { get; set; }

    [Required]
    public long InstitucionId { get; set; }

    [Required]
    public long SedeId { get; set; }

    [Required]
    public long AreaId { get; set; }

    [Required]
    public long ProcesoId { get; set; }

    [Required]
    public long ActividadId { get; set; }

    [Required]
    public long PuestoTrabajoId { get; set; }

    [Required]
    public long ResponsableId { get; set; }

    public long? AprobadorId { get; set; }
}
