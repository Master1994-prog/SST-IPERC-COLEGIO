using System.ComponentModel.DataAnnotations;

namespace SST.Application.Security.DTOs;

public sealed class LoginRequest
{
    [Required]
    public string Usuario { get; set; } = string.Empty;

    [Required]
    public string Password { get; set; } = string.Empty;
}
