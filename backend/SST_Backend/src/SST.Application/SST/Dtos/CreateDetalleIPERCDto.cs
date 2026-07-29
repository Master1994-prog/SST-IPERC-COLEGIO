using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para registrar un nuevo detalle dentro de una Matriz IPERC.
/// No usa directamente el enum del dominio para evitar dependencia directa en Application.
/// </summary>
public class CreateDetalleIPERCDto
{
    [Required]
    public long MatrizIPERCId { get; set; }

    /// <summary>
    /// Número correlativo dentro de la matriz.
    /// Si se envía 0, el backend asigna el siguiente número automáticamente.
    /// </summary>
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

    /// <summary>
    /// Controles aplicados al detalle IPERC.
    /// </summary>
    public List<long> ControlIds { get; set; } = new();

    /// <summary>
    /// Equipos de protección personal requeridos para el detalle IPERC.
    /// </summary>
    public List<long> EquipoProteccionIds { get; set; } = new();

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
