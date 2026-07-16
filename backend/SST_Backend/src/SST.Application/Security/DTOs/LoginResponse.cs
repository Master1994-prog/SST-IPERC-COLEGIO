namespace SST.Application.Security.DTOs;

public sealed class LoginResponse
{
    public string Token { get; set; } = string.Empty;

    public DateTime ExpiraEn { get; set; }

    public UsuarioLoginResponse Usuario { get; set; } = new();
}

public sealed class UsuarioLoginResponse
{
    public long Id { get; set; }

    public string NombreUsuario { get; set; } = string.Empty;

    public string Nombres { get; set; } = string.Empty;

    public string Apellidos { get; set; } = string.Empty;

    public string? Correo { get; set; }

    public long InstitucionId { get; set; }

    public long? SedeId { get; set; }

    public long? AreaId { get; set; }

    public bool DebeCambiarPassword { get; set; }

    public List<string> Roles { get; set; } = [];
}
