using System.ComponentModel.DataAnnotations;

namespace SST.Application.Security.DTOs;

public sealed class CambiarPasswordPropioRequest
{
    [Required]
    public string PasswordActual { get; set; } =
        string.Empty;

    [Required]
    [MinLength(8)]
    [MaxLength(100)]
    public string NuevaPassword { get; set; } =
        string.Empty;

    [Required]
    [Compare(
        nameof(NuevaPassword),
        ErrorMessage =
            "Las contraseñas no coinciden.")]
    public string ConfirmarPassword { get; set; } =
        string.Empty;
}