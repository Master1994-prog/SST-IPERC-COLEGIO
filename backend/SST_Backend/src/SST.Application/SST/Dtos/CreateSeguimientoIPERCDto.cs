using System.ComponentModel.DataAnnotations;

namespace SST.Application.SST.Dtos;

/// <summary>
/// DTO utilizado para registrar un seguimiento IPERC.
/// </summary>
public class CreateSeguimientoIPERCDto
{
    [Required]
    public long DetalleIPERCId { get; set; }

    [Required]
    public DateTime FechaSeguimiento { get; set; } = DateTime.UtcNow;

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
