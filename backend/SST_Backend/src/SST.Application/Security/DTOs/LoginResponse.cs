namespace SST.Application.Security.DTOs;

/// <summary>
/// Respuesta generada después de un inicio de sesión correcto.
/// </summary>
public sealed class LoginResponse
{
    public string Token { get; set; } =
        string.Empty;

    public DateTime ExpiraEn { get; set; }

    public UsuarioLoginResponse Usuario { get; set; } =
        new();
}

/// <summary>
/// Información del usuario autenticado que necesita Flutter.
/// </summary>
public sealed class UsuarioLoginResponse
{
    public long Id { get; set; }

    public string NombreUsuario { get; set; } =
        string.Empty;

    public string Nombres { get; set; } =
        string.Empty;

    public string Apellidos { get; set; } =
        string.Empty;

    public string? Correo { get; set; }

    public long InstitucionId { get; set; }

    public long? SedeId { get; set; }

    public long? AreaId { get; set; }

    /// <summary>
    /// True cuando el usuario debe cambiar su contraseña
    /// antes de acceder normalmente al sistema.
    /// </summary>
    public bool DebeCambiarPassword { get; set; }

    /// <summary>
    /// Sesiones online realizadas desde el último
    /// cambio válido de contraseña.
    /// </summary>
    public int SesionesDesdeCambioPassword { get; set; }

    /// <summary>
    /// Sesiones que faltan para llegar al límite de 30.
    /// </summary>
    public int SesionesRestantesCambioPassword { get; set; }

    /// <summary>
    /// True únicamente en las sesiones:
    /// 5, 10, 15, 20 y 25.
    /// </summary>
    public bool RecordarCambioPassword { get; set; }

    public List<string> Roles { get; set; } = [];
}