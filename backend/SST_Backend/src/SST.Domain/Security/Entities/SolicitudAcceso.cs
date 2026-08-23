using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SST.Domain.Security.Entities;

/// <summary>
/// Solicitud realizada por una persona que requiere
/// acceso al sistema SST EduRisk.
/// </summary>
[Table("solicitudesacceso")]
public class SolicitudAcceso
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public long Id { get; set; }

    [Required]
    [MaxLength(150)]
    public string Nombres { get; set; } = string.Empty;

    [Required]
    [MaxLength(150)]
    public string Apellidos { get; set; } = string.Empty;

    [Required]
    [MaxLength(200)]
    public string Correo { get; set; } = string.Empty;

    [Required]
    [MaxLength(200)]
    public string Institucion { get; set; } = string.Empty;

    [MaxLength(150)]
    public string? Cargo { get; set; }

    [MaxLength(1000)]
    public string? Motivo { get; set; }

    /// <summary>
    /// PENDIENTE / APROBADA / RECHAZADA
    /// </summary>
    [Required]
    [MaxLength(30)]
    public string EstadoSolicitud { get; set; } = "PENDIENTE";

    public DateTime FechaSolicitud { get; set; } = DateTime.UtcNow;

    public DateTime? FechaAtencion { get; set; }
}