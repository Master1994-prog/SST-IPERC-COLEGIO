using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para actualizar un detalle de Matriz IPERC.
/// No contiene Id porque el Id llega desde la ruta.
/// </summary>
public class UpdateDetalleIPERCDto
{
    [Required]
    public long MatrizIPERCId { get; set; }

    public int Item { get; set; }

    [Required]
    [MaxLength(250)]
    public string Tarea { get; set; } = string.Empty;

    [Required]
    public long PeligroId { get; set; }

    [Required]
    public long ConsecuenciaId { get; set; }

    [MaxLength(1000)]
    public string? DescripcionPeligro { get; set; }

    [Required]
    public long EvaluacionInicialId { get; set; }

    public long? EvaluacionResidualId { get; set; }

    public long? ResponsableImplementacionId { get; set; }

    public DateTime? FechaCompromiso { get; set; }

    public DateTime? FechaImplementacion { get; set; }

    /// <summary>
    /// Estado de implementación.
    /// 0 = Pendiente
    /// 1 = EnProceso
    /// 2 = Implementado
    /// 3 = Verificado
    /// 4 = Cerrado
    /// </summary>
    public int EstadoImplementacion { get; set; } = 0;
}
