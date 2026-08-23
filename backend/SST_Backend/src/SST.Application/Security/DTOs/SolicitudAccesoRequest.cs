using System.ComponentModel.DataAnnotations;

namespace SST.Application.Security.DTOs;

public sealed class SolicitudAccesoRequest
{
    [Required]
    [MaxLength(150)]
    public string Nombres { get; set; } = string.Empty;

    [Required]
    [MaxLength(150)]
    public string Apellidos { get; set; } = string.Empty;

    [Required]
    [EmailAddress]
    [MaxLength(200)]
    public string Correo { get; set; } = string.Empty;

    [Required]
    [MaxLength(200)]
    public string Institucion { get; set; } = string.Empty;

    [MaxLength(150)]
    public string? Cargo { get; set; }

    [MaxLength(1000)]
    public string? Motivo { get; set; }
}