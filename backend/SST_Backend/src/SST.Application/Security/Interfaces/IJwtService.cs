using SST.Domain.Security.Entities;

namespace SST.Application.Security.Interfaces;

public interface IJwtService
{
    string GenerarToken(
        Usuario usuario,
        IReadOnlyCollection<string> roles,
        out DateTime fechaExpiracion);
}
