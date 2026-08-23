using System.ComponentModel.DataAnnotations;

namespace SST.Application.Security.DTOs;

public sealed class RecuperarPasswordRequest
{
    [Required]
    [MaxLength(200)]
    public string Identificador { get; set; } = string.Empty;
}