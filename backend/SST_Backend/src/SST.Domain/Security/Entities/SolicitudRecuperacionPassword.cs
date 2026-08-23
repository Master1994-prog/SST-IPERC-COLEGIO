using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SST.Domain.Security.Entities;

/// <summary>
/// Solicitud de recuperación de contraseña.
///
/// No almacena contraseñas ni códigos secretos.
/// </summary>
[Table("solicitudesrecuperacionpassword")]
public class SolicitudRecuperacionPassword
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public long Id { get; set; }

    /// <summary>
    /// Usuario encontrado en el sistema.
    /// Se mantiene nullable para evitar revelar al solicitante
    /// si la cuenta realmente existe.
    /// </summary>
    public long? UsuarioId { get; set; }

    [Required]
    [MaxLength(200)]
    public string Identificador { get; set; } = string.Empty;

    [MaxLength(200)]
    public string? Correo { get; set; }

    /// <summary>
    /// PENDIENTE / ATENDIDA / RECHAZADA
    /// </summary>
    [Required]
    [MaxLength(30)]
    public string EstadoSolicitud { get; set; } = "PENDIENTE";

    public DateTime FechaSolicitud { get; set; } = DateTime.UtcNow;

    public DateTime? FechaAtencion { get; set; }
}