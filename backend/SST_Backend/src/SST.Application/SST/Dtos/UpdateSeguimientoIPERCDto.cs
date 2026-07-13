using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para actualizar un seguimiento IPERC.
/// No contiene Id porque el Id llega desde la ruta.
/// </summary>
public class UpdateSeguimientoIPERCDto
{
    [Required]
    public long DetalleIPERCId { get; set; }

    [Required]
    public DateTime FechaSeguimiento { get; set; }

    [Required]
    public long UsuarioId { get; set; }

    [Required]
    [MaxLength(3000)]
    public string Descripcion { get; set; } = string.Empty;

    [Range(0, 100)]
    public decimal PorcentajeAvance { get; set; }

    public bool Verificado { get; set; }

    public DateTime? FechaVerificacion { get; set; }

    [MaxLength(3000)]
    public string? Observaciones { get; set; }

    [MaxLength(500)]
    public string? Archivo { get; set; }

    [MaxLength(250)]
    public string? NombreArchivo { get; set; }

    [MaxLength(100)]
    public string? TipoArchivo { get; set; }
}
